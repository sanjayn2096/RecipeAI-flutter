import 'package:recipe_ai/l10n/app_localizations.dart';

import 'constants.dart';
import 'preference_options.dart';
import 'recipe_generation_entry_point.dart';
import '../services/session_manager.dart';

/// Human-readable summary of inputs that drive `POST generate-recipe`
/// (mirrors [RecipeRepository.fetchRecipesFromBackend]).
class RecipeSearchContext {
  const RecipeSearchContext({
    required this.headline,
    required this.detailLines,
    required this.ingredientLabels,
    required this.dietProfileLabels,
    required this.allergenLabels,
    this.allergyNotes,
  });

  final String headline;
  final List<String> detailLines;
  final List<String> ingredientLabels;
  final List<String> dietProfileLabels;
  final List<String> allergenLabels;
  final String? allergyNotes;

  static RecipeSearchContext fromSession(
    SessionManager session,
    AppLocalizations l10n,
  ) {
    return fromSessionForEntryPoint(
      session,
      RecipeGenerationEntryPoint.createRecipes,
      l10n,
    );
  }

  /// Summarizes inputs for the given generation entry point (Create flow vs Home).
  static RecipeSearchContext fromSessionForEntryPoint(
    SessionManager session,
    RecipeGenerationEntryPoint entryPoint,
    AppLocalizations l10n,
  ) {
    final custom =
        session.getPreference(AppConstants.prefsCustomPreference)?.trim() ?? '';

    final mood = entryPoint == RecipeGenerationEntryPoint.home
        ? session.getLifestyleMood()
        : session.getCreateFlowMood();
    final dietLine = entryPoint == RecipeGenerationEntryPoint.home
        ? session.getLifestyleDietRestrictions()
        : session.getCreateFlowDietRestrictions();
    final cuisine = entryPoint == RecipeGenerationEntryPoint.home
        ? _homePreferredCuisinesJoined(session, l10n)
        : session.getCreateFlowCuisine();
    final cooking = entryPoint == RecipeGenerationEntryPoint.home
        ? session.getLifestyleCookingPreference()
        : session.getCreateFlowCookingPreference();

    final ingredients = session.getIngredients();
    final dietProfiles = session.getDietProfiles();
    final allergens = session.getAllergensAvoid();
    final notes = session.getAllergyNotes()?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;

    final headline = () {
      if (custom.isNotEmpty) return l10n.searchHeadlineBasedOnCustom;
      if (entryPoint == RecipeGenerationEntryPoint.createRecipes) {
        return l10n.searchHeadlineCreateRecipes;
      }
      if (PreferenceOptions.isFeelingLucky(mood)) {
        return l10n.searchHeadlineLuckyMode;
      }
      if (entryPoint == RecipeGenerationEntryPoint.home) {
        return l10n.searchHeadlineSavedPreferences;
      }
      return l10n.searchHeadlineQuestionnaire;
    }();

    final lines = <String>[];

    if (custom.isNotEmpty) {
      lines.add(custom.length > 200 ? '${custom.substring(0, 197)}…' : custom);
    }

    if (custom.isEmpty &&
        mood.trim().isNotEmpty &&
        !PreferenceOptions.isFeelingLucky(mood)) {
      lines.add(l10n.searchDetailMood(PreferenceOptions.moodLabel(mood, l10n)));
    }

    if (_meaningfulDiet(dietLine)) {
      final homeUsesProfileDiets = entryPoint ==
              RecipeGenerationEntryPoint.home &&
          dietProfiles.isNotEmpty;
      if (!homeUsesProfileDiets) {
        lines.add(l10n.searchDetailDiet(PreferenceOptions.dietLabel(dietLine, l10n)));
      }
    }

    if (_meaningfulCuisine(cuisine, entryPoint)) {
      final cuisineLabel = entryPoint == RecipeGenerationEntryPoint.home
          ? _formatCuisineList(cuisine, l10n)
          : PreferenceOptions.cuisineLabel(cuisine, l10n);
      if (entryPoint == RecipeGenerationEntryPoint.home) {
        lines.add(l10n.searchDetailPreferredCuisines(cuisineLabel));
      } else {
        lines.add(l10n.searchDetailCuisine(cuisineLabel));
      }
    }

    if (_meaningfulCooking(cooking)) {
      final cookLabel = PreferenceOptions.cookingLabel(cooking, l10n);
      if (entryPoint == RecipeGenerationEntryPoint.home) {
        lines.add(l10n.searchDetailCookingProficiency(cookLabel));
      } else {
        lines.add(l10n.searchDetailTime(cookLabel));
      }
    }

    return RecipeSearchContext(
      headline: headline,
      detailLines: lines,
      ingredientLabels: List<String>.from(ingredients),
      dietProfileLabels: dietProfiles
          .map((k) => PreferenceOptions.dietLabel(k, l10n))
          .toList(),
      allergenLabels: allergens
          .map((k) => PreferenceOptions.allergenLabel(k, l10n))
          .toList(),
      allergyNotes: hasNotes ? notes : null,
    );
  }

  static String _homePreferredCuisinesJoined(
    SessionManager session,
    AppLocalizations l10n,
  ) {
    final usual = session
        .getUsualCuisines()
        .where(
          (e) =>
              e.isNotEmpty &&
              !PreferenceOptions.isSurpriseCuisine(e),
        )
        .toList();
    if (usual.isNotEmpty) {
      return usual.map((k) => PreferenceOptions.cuisineLabel(k, l10n)).join(', ');
    }
    return session.getLifestyleCuisine();
  }

  static String _formatCuisineList(String cuisine, AppLocalizations l10n) {
    if (cuisine.contains(',')) {
      return cuisine
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map((k) => PreferenceOptions.cuisineLabel(k, l10n))
          .join(', ');
    }
    return PreferenceOptions.cuisineLabel(cuisine, l10n);
  }

  static bool _meaningfulDiet(String key) =>
      !PreferenceOptions.isNoRestrictionsDiet(key);

  static bool _meaningfulCuisine(String key, RecipeGenerationEntryPoint ep) {
    if (key.trim().isEmpty) return false;
    if (ep == RecipeGenerationEntryPoint.home && key.contains(',')) {
      return true;
    }
    return !PreferenceOptions.isNoCuisineSelected(key);
  }

  static bool _meaningfulCooking(String key) =>
      !PreferenceOptions.isNotParticularCooking(key);
}
