import 'package:flutter/foundation.dart';

import 'app_strings.dart';
import 'constants.dart';
import 'recipe_generation_entry_point.dart';
import '../services/session_manager.dart';

/// Human-readable summary of inputs that drive `POST generate-recipe`
/// (mirrors [RecipeRepository.fetchRecipesFromBackend]).
@immutable
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

  static RecipeSearchContext fromSession(SessionManager session) {
    final custom =
        session.getPreference(AppConstants.prefsCustomPreference)?.trim() ?? '';
    final mood = session.getMood() ?? '';
    final dietLine =
        session.getDietRestrictions() ?? 'No Diet Restrictions';
    final cuisine = session.getCuisine() ?? 'No Cuisine Selected';
    final cooking = session.getCookingPreference() ?? 'No Cooking Preferences';
    final ingredients = session.getIngredients();
    final dietProfiles = session.getDietProfiles();
    final allergens = session.getAllergensAvoid();
    final notes = session.getAllergyNotes()?.trim();
    final hasNotes = notes != null && notes.isNotEmpty;

    final headline = () {
      if (custom.isNotEmpty) return 'Based on what you asked for';
      if (mood.trim() == AppStrings.feelingLucky) return 'Variety picks (lucky mode)';
      return 'Using your questionnaire and pantry choices';
    }();

    final lines = <String>[];

    if (custom.isNotEmpty) {
      lines.add(custom.length > 200 ? '${custom.substring(0, 197)}…' : custom);
    }

    if (custom.isEmpty && mood.trim().isNotEmpty &&
        mood.trim() != AppStrings.feelingLucky) {
      lines.add('Mood: $mood');
    }

    if (_meaningfulDiet(dietLine)) {
      lines.add('Diet: $dietLine');
    }

    if (_meaningfulCuisine(cuisine)) {
      lines.add('Cuisine: $cuisine');
    }

    if (_meaningfulCooking(cooking)) {
      lines.add('Time: $cooking');
    }

    return RecipeSearchContext(
      headline: headline,
      detailLines: lines,
      ingredientLabels: List<String>.from(ingredients),
      dietProfileLabels: List<String>.from(dietProfiles),
      allergenLabels: List<String>.from(allergens),
      allergyNotes: hasNotes ? notes : null,
    );
  }

  /// Summarizes inputs for the given generation entry point (Create flow vs Home vs legacy).
  static RecipeSearchContext fromSessionForEntryPoint(
    SessionManager session,
    RecipeGenerationEntryPoint entryPoint,
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
        ? (_homePreferredCuisinesJoined(session))
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
      if (custom.isNotEmpty) return 'Based on what you asked for';
      if (entryPoint == RecipeGenerationEntryPoint.createRecipes) {
        return 'Using your Create Recipes preferences';
      }
      if (mood.trim() == AppStrings.feelingLucky) {
        return 'Variety picks (lucky mode)';
      }
      return 'Using your saved preferences';
    }();

    final lines = <String>[];

    if (custom.isNotEmpty) {
      lines.add(custom.length > 200 ? '${custom.substring(0, 197)}…' : custom);
    }

    if (entryPoint == RecipeGenerationEntryPoint.home) {
      if (custom.isEmpty && dietProfiles.isNotEmpty) {
        lines.add('Diets (profile): ${dietProfiles.join(', ')}');
      }
    }

    if (custom.isEmpty &&
        mood.trim().isNotEmpty &&
        mood.trim() != AppStrings.feelingLucky) {
      lines.add('Mood: $mood');
    }

    if (_meaningfulDiet(dietLine)) {
      if (entryPoint == RecipeGenerationEntryPoint.home) {
        lines.add('Diet summary line: $dietLine');
      } else {
        lines.add('Diet: $dietLine');
      }
    }

    if (_meaningfulCuisine(cuisine)) {
      if (entryPoint == RecipeGenerationEntryPoint.home) {
        lines.add('Preferred cuisines: $cuisine');
      } else {
        lines.add('Cuisine: $cuisine');
      }
    }

    if (_meaningfulCooking(cooking)) {
      if (entryPoint == RecipeGenerationEntryPoint.home) {
        lines.add('Cooking proficiency: $cooking');
      } else {
        lines.add('Time: $cooking');
      }
    }

    return RecipeSearchContext(
      headline: headline,
      detailLines: lines,
      ingredientLabels: List<String>.from(ingredients),
      dietProfileLabels: List<String>.from(dietProfiles),
      allergenLabels: List<String>.from(allergens),
      allergyNotes: hasNotes ? notes : null,
    );
  }

  /// Mirrors [RecipeRepository] home resolution: preferred list, then legacy single field.
  static String _homePreferredCuisinesJoined(SessionManager session) {
    final usual = session
        .getUsualCuisines()
        .map((e) => e.trim())
        .where(
          (e) =>
              e.isNotEmpty &&
              e != AppStrings.surpriseMe,
        )
        .toList();
    if (usual.isNotEmpty) {
      return usual.join(', ');
    }
    return session.getLifestyleCuisine();
  }

  static bool _meaningfulDiet(String s) {
    final t = s.trim();
    if (t.isEmpty) return false;
    if (t == 'No Diet Restrictions' ||
        t == AppStrings.noRestrictions ||
        t == 'No Restrictions') {
      return false;
    }
    return true;
  }

  static bool _meaningfulCuisine(String s) {
    final t = s.trim();
    if (t.isEmpty || t == 'No Cuisine Selected') return false;
    return true;
  }

  static bool _meaningfulCooking(String s) {
    final t = s.trim();
    if (t.isEmpty ||
        t == 'No Cooking Preferences' ||
        t == AppStrings.notParticular) {
      return false;
    }
    return true;
  }
}
