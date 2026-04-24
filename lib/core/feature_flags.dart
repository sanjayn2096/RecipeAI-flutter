/// Feature flags and experiment routing for recipe generation.
class FeatureFlags {
  FeatureFlags._();

  /// `control` -> always use POST /generate-recipe
  /// `stream` -> always use POST /generate-recipes-stream
  /// `experiment` -> stable actor bucketing between both endpoints
  ///
  /// Default is `stream` so local runs test streaming without `--dart-define`.
  /// For A/B or the non-stream path: `--dart-define=RECIPE_GENERATION_MODE=control`
  /// (or `experiment`).
  static const String recipeGenerationMode =
      String.fromEnvironment('RECIPE_GENERATION_MODE', defaultValue: 'stream');

  /// Used only when [recipeGenerationMode] is `experiment`.
  /// Example: 50 means 50% of actors use streaming endpoint.
  static const int recipeStreamRolloutPercent =
      int.fromEnvironment('RECIPE_STREAM_ROLLOUT_PERCENT', defaultValue: 50);

  static bool useStreamingRecipeGeneration(String actorId) {
    switch (recipeGenerationMode) {
      case 'stream':
        return true;
      case 'experiment':
        final clamped = recipeStreamRolloutPercent.clamp(0, 100);
        return _bucket(actorId) < clamped;
      case 'control':
      default:
        return false;
    }
  }

  /// Stable 0..99 bucket for deterministic A/B routing.
  static int _bucket(String value) {
    var hash = 0;
    for (final rune in value.runes) {
      hash = ((hash * 31) + rune) & 0x7fffffff;
    }
    return hash % 100;
  }

  /// When false, the recipe screen does not hydrate from Firestore or call the image API in the background.
  /// Example: `--dart-define=RECIPE_IMAGES_AUTO_GENERATE=false`
  static const bool recipeImagesAutoGenerateOnOpen =
      bool.fromEnvironment('RECIPE_IMAGES_AUTO_GENERATE', defaultValue: true);
}
