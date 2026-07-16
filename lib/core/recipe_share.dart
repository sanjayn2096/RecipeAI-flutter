/// Shared recipe HTTPS links (`https://souschefai.app/r/{recipeId}`).
class RecipeShare {
  RecipeShare._();

  static const siteOrigin = 'https://souschefai.app';

  static String urlForRecipeId(String recipeId) {
    final id = recipeId.trim();
    if (id.isEmpty) return siteOrigin;
    return '$siteOrigin/r/${Uri.encodeComponent(id)}';
  }

  static String shareText({
    required String recipeName,
    required String recipeId,
  }) {
    final name = recipeName.trim().isEmpty ? 'this recipe' : recipeName.trim();
    return 'Check out $name on Sous Chef\n${urlForRecipeId(recipeId)}';
  }

  /// Returns a recipe id from `https://souschefai.app/r/{id}` (or path-only `/r/{id}`).
  static String? recipeIdFromUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'r') {
      final id = Uri.decodeComponent(segments[1]).trim();
      return id.isEmpty ? null : id;
    }
    return null;
  }
}
