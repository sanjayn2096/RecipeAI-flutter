import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
    await p.remove(_prefix + AppConstants.prefsGuestMode);
    await p.remove(_prefix + AppConstants.prefsAnonymousId);
    await p.remove(_prefix + AppConstants.prefsGuestGenDayKey);
    await p.remove(_prefix + AppConstants.prefsGuestGenCount);
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

  bool isGuestMode() =>
      _prefs?.getBool(_prefix + AppConstants.prefsGuestMode) ?? false;

  void setGuestModeSync(bool value) {
    _prefs?.setBool(_prefix + AppConstants.prefsGuestMode, value);
  }

  void clearGuestModeSync() {
    _prefs?.remove(_prefix + AppConstants.prefsGuestMode);
  }

  /// Clears guest-only ids used for anonymous API quota (call when user signs in with a real account).
  void clearAnonymousAndGuestQuotaSync() {
    _prefs?.remove(_prefix + AppConstants.prefsAnonymousId);
    _prefs?.remove(_prefix + AppConstants.prefsGuestGenDayKey);
    _prefs?.remove(_prefix + AppConstants.prefsGuestGenCount);
  }

  static String guestQuotaUtcDayKeyNow() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<String> getOrCreateAnonymousId() async {
    final p = await _p;
    final key = _prefix + AppConstants.prefsAnonymousId;
    final existing = p.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = const Uuid().v4();
    await p.setString(key, id);
    return id;
  }

  /// Client-side mirror of daily guest cap (2/day); server still enforces.
  Future<bool> isGuestRecipeQuotaExceededForToday() async {
    if (!isGuestMode()) return false;
    final p = await _p;
    final day = guestQuotaUtcDayKeyNow();
    final storedDay = p.getString(_prefix + AppConstants.prefsGuestGenDayKey);
    if (storedDay != day) return false;
    final n = p.getInt(_prefix + AppConstants.prefsGuestGenCount) ?? 0;
    return n >= 2;
  }

  /// After a successful generate-recipe for a guest (no Firebase user).
  Future<void> recordGuestRecipeGenerationSuccess() async {
    if (!isGuestMode()) return;
    final p = await _p;
    final day = guestQuotaUtcDayKeyNow();
    final keyDay = _prefix + AppConstants.prefsGuestGenDayKey;
    final keyCount = _prefix + AppConstants.prefsGuestGenCount;
    final storedDay = p.getString(keyDay);
    int count = 0;
    if (storedDay == day) {
      count = p.getInt(keyCount) ?? 0;
    }
    await p.setString(keyDay, day);
    await p.setInt(keyCount, count + 1);
  }
}
