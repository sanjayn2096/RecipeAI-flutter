import 'package:recipe_ai/l10n/app_localizations.dart';

import 'preference_options.dart';

/// Helpers on generated [AppLocalizations] for lists and questionnaire routes.
extension AppLocalizationsHelpers on AppLocalizations {
  List<String> get recipeGenerationLoadingPhrases => [
        recipeLoadingPhrase0,
        recipeLoadingPhrase1,
        recipeLoadingPhrase2,
        recipeLoadingPhrase3,
        recipeLoadingPhrase4,
        recipeLoadingPhrase5,
        recipeLoadingPhrase6,
        recipeLoadingPhrase7,
        recipeLoadingPhrase8,
        recipeLoadingPhrase9,
        recipeLoadingPhrase10,
      ];

  List<String> get recipeGenerationLoadingPhrasesStreamingExtras => [
        recipeLoadingStreamingExtra0,
        recipeLoadingStreamingExtra1,
      ];

  String titleForRoute(String route) {
    switch (route) {
      case 'mood':
        return howAreYouFeelingToday;
      case 'dietRestrictions':
        return doYouHaveDietaryRestrictions;
      case 'cuisinePreferences':
        return whatCuisineDoYouFeelLike;
      case 'cookingPreferences':
        return howMuchTimeCooking;
      default:
        return '';
    }
  }

  String? nextRoute(String route) {
    switch (route) {
      case 'mood':
        return 'dietRestrictions';
      case 'dietRestrictions':
        return 'cuisinePreferences';
      case 'cuisinePreferences':
        return 'cookingPreferences';
      case 'cookingPreferences':
        return 'recipeActivity';
      default:
        return null;
    }
  }

  String? previousRoute(String route) {
    switch (route) {
      case 'mood':
        return null;
      case 'dietRestrictions':
        return 'mood';
      case 'cuisinePreferences':
        return 'dietRestrictions';
      case 'cookingPreferences':
        return 'cuisinePreferences';
      default:
        return null;
    }
  }

  String moodLabel(String key) => PreferenceOptions.moodLabel(key, this);

  String dietLabel(String key) => PreferenceOptions.dietLabel(key, this);

  String cuisineLabel(String key) => PreferenceOptions.cuisineLabel(key, this);

  String cookingLabel(String key) => PreferenceOptions.cookingLabel(key, this);

  String allergenLabel(String key) => PreferenceOptions.allergenLabel(key, this);

  List<String> get moodOptionKeys => PreferenceOptions.moodKeys;

  List<String> get dietOptionKeys => PreferenceOptions.dietKeys;

  List<String> get cuisineOptionKeys => PreferenceOptions.cuisineKeys;

  List<String> get cookingTimeOptionKeys => PreferenceOptions.cookingKeys;

  List<String> get preferredCuisineOptionKeys =>
      PreferenceOptions.preferredCuisineKeys;

  List<String> get dietMultiSelectOptionKeys =>
      PreferenceOptions.dietMultiSelectKeys;

  List<String> get commonAllergenKeys => PreferenceOptions.allergenKeys;
}
