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
  }

  Future<void> saveUserId(String userId) async {
    (await _p).setString(_prefix + AppConstants.prefsUserId, userId);
  }

  String? getUserId() => _prefs?.getString(_prefix + AppConstants.prefsUserId);

  Future<void> saveEmail(String email) async {
    (await _p).setString(_prefix + AppConstants.prefsEmail, email);
  }

  String? getEmail() => _prefs?.getString(_prefix + AppConstants.prefsEmail) ?? 'john.doe@example.com';

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
}
