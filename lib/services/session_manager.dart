import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

/// Single source for session and user preferences (injected, no duplicate instances).
class SessionManager {
  SessionManager({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const String _prefix = 'recipe_ai_';

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> saveSession(String sessionId) async {
    (await _p).setString(_prefix + AppConstants.prefsSessionId, sessionId);
  }

  String? getSession() => _prefs?.getString(_prefix + AppConstants.prefsSessionId);

  Future<void> clearSession() async {
    final p = await _p;
    await p.remove(_prefix + AppConstants.prefsSessionId);
    await p.remove(_prefix + AppConstants.prefsUserId);
    await p.remove(_prefix + AppConstants.prefsEmail);
    await p.remove(_prefix + AppConstants.prefsFirstName);
    await p.remove(_prefix + AppConstants.prefsLastName);
    await p.remove(_prefix + AppConstants.prefsIngredients);
  }

  Future<void> saveUserId(String userId) async {
    (await _p).setString(_prefix + AppConstants.prefsUserId, userId);
  }

  String? getUserId() => _prefs?.getString(_prefix + AppConstants.prefsUserId);

  Future<void> saveEmail(String email) async {
    (await _p).setString(_prefix + AppConstants.prefsEmail, email);
  }

  /// Raw stored email (no placeholder).
  String? getStoredEmail() => _prefs?.getString(_prefix + AppConstants.prefsEmail);

  /// Email for API calls; falls back to empty string if unset.
  String? getEmail() => getStoredEmail();

  Future<void> saveFirstName(String? value) async {
    final p = await _p;
    final key = _prefix + AppConstants.prefsFirstName;
    if (value == null || value.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, value.trim());
    }
  }

  Future<void> saveLastName(String? value) async {
    final p = await _p;
    final key = _prefix + AppConstants.prefsLastName;
    if (value == null || value.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, value.trim());
    }
  }

  String? getFirstName() => _prefs?.getString(_prefix + AppConstants.prefsFirstName);

  String? getLastName() => _prefs?.getString(_prefix + AppConstants.prefsLastName);

  /// Persists all fields returned from GET get_user_profile.
  Future<void> persistUserProfile({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    await saveUserId(userId);
    await saveEmail(email);
    await saveFirstName(firstName);
    await saveLastName(lastName);
  }

  Future<void> savePreference(String key, String value) async {
    (await _p).setString(_prefix + key, value);
  }

  String? getPreference(String key) {
    return _prefs?.getString(_prefix + key);
  }

  void savePreferenceSync(String key, String value) {
    _prefs?.setString(_prefix + key, value);
  }

  String? getMood() => getPreference(AppConstants.prefsMood) ?? 'lucky';
  String? getCuisine() => getPreference(AppConstants.prefsCuisine) ?? 'No Cuisine Selected';
  String? getCookingPreference() => getPreference(AppConstants.prefsCookingPreference) ?? 'No Cooking Preferences';
  String? getDietRestrictions() => getPreference(AppConstants.prefsDietRestrictions) ?? 'No Diet Restrictions';

  /// Chosen pantry / ingredient labels for the prompt (see [PromptBuilder]).
  List<String> getIngredients() {
    final list = _prefs?.getStringList(_prefix + AppConstants.prefsIngredients);
    return list ?? const [];
  }

  Future<void> saveIngredients(List<String> ingredients) async {
    await (await _p).setStringList(
      _prefix + AppConstants.prefsIngredients,
      ingredients,
    );
  }

  void saveIngredientsSync(List<String> ingredients) {
    _prefs?.setStringList(
      _prefix + AppConstants.prefsIngredients,
      ingredients,
    );
  }
}
