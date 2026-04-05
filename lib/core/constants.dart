/// App and API constants.
class AppConstants {
  AppConstants._();

  /// Firebase project ID (recipeai-89d8b). Used for reference / config.
  static const String firebaseProjectId = 'recipeai-89d8b';

  static const String prefsSessionId = 'SESSION_ID';
  static const String prefsUserId = 'USER_ID';
  static const String prefsEmail = 'email';
  static const String prefsFirstName = 'firstName';
  static const String prefsLastName = 'lastName';
  static const String prefsMood = 'mood';
  static const String prefsCuisine = 'cuisinePreferences';
  static const String prefsCookingPreference = 'cookingPreferences';
  static const String prefsDietRestrictions = 'dietRestrictions';
  static const String prefsCustomPreference = 'customPreference';
  /// Pantry / chosen ingredient labels (persisted as string list).
  static const String prefsIngredients = 'ingredients';
  /// Browse app without account; cleared on real login or session clear.
  static const String prefsGuestMode = 'guestMode';

  /// Stable id for POST generate-recipe when not signed in (device-local; new after reinstall).
  static const String prefsAnonymousId = 'anonymousId';

  /// UTC calendar day `YYYY-MM-DD` for guest recipe quota mirror (align with backend dayKey).
  static const String prefsGuestGenDayKey = 'guestGenDayKey';

  /// Successful guest generate-recipe calls counted for [prefsGuestGenDayKey].
  static const String prefsGuestGenCount = 'guestGenCount';

  /// Hive box for cached GET fetch-favorites JSON (`userId` + `recipes`).
  static const String hiveFavoritesBox = 'favorites_cache';
}
