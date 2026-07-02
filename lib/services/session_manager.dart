import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/constants.dart';
import '../core/preference_options.dart';
import '../data/models/subscription_status.dart';
import '../onboarding/onboarding_prefs.dart';

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
    await p.remove(_prefix + AppConstants.prefsUsualCuisines);
    await p.remove(_prefix + AppConstants.prefsDietProfiles);
    await p.remove(_prefix + AppConstants.prefsAllergensAvoid);
    await p.remove(_prefix + AppConstants.prefsAllergyNotes);
    await p.remove(_prefix + OnboardingPrefs.onboardingComplete);
    await p.remove(_prefix + OnboardingPrefs.onboardingCompleteUserId);
    await p.remove(_prefix + AppConstants.prefsGuestMode);
    await p.remove(_prefix + AppConstants.prefsAnonymousId);
    await p.remove(_prefix + AppConstants.prefsGuestGenDayKey);
    await p.remove(_prefix + AppConstants.prefsGuestGenCount);
    await p.remove(_prefix + AppConstants.prefsSubscriptionCache);
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
    const key = _prefix + AppConstants.prefsFirstName;
    if (value == null || value.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, value.trim());
    }
  }

  Future<void> saveLastName(String? value) async {
    final p = await _p;
    const key = _prefix + AppConstants.prefsLastName;
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

  /// Legacy mood field — prefer [getLifestyleMood] / [getCreateFlowMood] by flow.
  String? getMood() =>
      PreferenceOptions.normalizeMoodKey(
        getPreference(AppConstants.prefsMood) ?? PreferenceOptions.moodFeelingLucky,
      );

  /// Global lifestyle default for Home generation and PATCH sync (falls back to legacy [prefsMood] once).
  String getLifestyleMood() => PreferenceOptions.normalizeMoodKey(
        getPreference(AppConstants.prefsLifestyleMood) ??
            getPreference(AppConstants.prefsMood) ??
            PreferenceOptions.moodFeelingLucky,
      );

  String getLifestyleCuisine() => PreferenceOptions.normalizeCuisineKey(
        getPreference(AppConstants.prefsLifestyleCuisine) ??
            getPreference(AppConstants.prefsCuisine) ??
            PreferenceOptions.noCuisineSelected,
      );

  String getLifestyleCookingPreference() => PreferenceOptions.normalizeCookingKey(
        getPreference(AppConstants.prefsLifestyleCookingPreference) ??
            getPreference(AppConstants.prefsCookingPreference) ??
            PreferenceOptions.noCookingPreference,
      );

  String getLifestyleDietRestrictions() => PreferenceOptions.normalizeDietKey(
        getPreference(AppConstants.prefsLifestyleDietRestrictions) ??
            getPreference(AppConstants.prefsDietRestrictions) ??
            PreferenceOptions.noDietRestrictions,
      );

  void saveLifestyleMoodSync(String value) =>
      savePreferenceSync(AppConstants.prefsLifestyleMood, value);

  void saveLifestyleCuisineSync(String value) =>
      savePreferenceSync(AppConstants.prefsLifestyleCuisine, value);

  void saveLifestyleCookingPreferenceSync(String value) =>
      savePreferenceSync(AppConstants.prefsLifestyleCookingPreference, value);

  void saveLifestyleDietRestrictionsSync(String value) =>
      savePreferenceSync(AppConstants.prefsLifestyleDietRestrictions, value);

  /// Create Recipes questionnaire only (falls back to legacy keys until user re-saves).
  String getCreateFlowMood() => PreferenceOptions.normalizeMoodKey(
        getPreference(AppConstants.prefsCreateFlowMood) ??
            getPreference(AppConstants.prefsMood) ??
            PreferenceOptions.moodFeelingLucky,
      );

  String getCreateFlowCuisine() => PreferenceOptions.normalizeCuisineKey(
        getPreference(AppConstants.prefsCreateFlowCuisine) ??
            getPreference(AppConstants.prefsCuisine) ??
            PreferenceOptions.noCuisineSelected,
      );

  String getCreateFlowCookingPreference() => PreferenceOptions.normalizeCookingKey(
        getPreference(AppConstants.prefsCreateFlowCookingPreference) ??
            getPreference(AppConstants.prefsCookingPreference) ??
            PreferenceOptions.noCookingPreference,
      );

  String getCreateFlowDietRestrictions() => PreferenceOptions.normalizeDietKey(
        getPreference(AppConstants.prefsCreateFlowDietRestrictions) ??
            getPreference(AppConstants.prefsDietRestrictions) ??
            PreferenceOptions.noDietRestrictions,
      );

  void saveCreateFlowMoodSync(String value) =>
      savePreferenceSync(AppConstants.prefsCreateFlowMood, value);

  void saveCreateFlowCuisineSync(String value) =>
      savePreferenceSync(AppConstants.prefsCreateFlowCuisine, value);

  void saveCreateFlowCookingPreferenceSync(String value) =>
      savePreferenceSync(AppConstants.prefsCreateFlowCookingPreference, value);

  void saveCreateFlowDietRestrictionsSync(String value) =>
      savePreferenceSync(AppConstants.prefsCreateFlowDietRestrictions, value);

  String? getCuisine() => PreferenceOptions.normalizeCuisineKey(
        getPreference(AppConstants.prefsCuisine) ??
            PreferenceOptions.noCuisineSelected,
      );
  String? getCookingPreference() => PreferenceOptions.normalizeCookingKey(
        getPreference(AppConstants.prefsCookingPreference) ??
            PreferenceOptions.noCookingPreference,
      );
  String? getDietRestrictions() => PreferenceOptions.normalizeDietKey(
        getPreference(AppConstants.prefsDietRestrictions) ??
            PreferenceOptions.noDietRestrictions,
      );

  List<String> getDietProfiles() {
    final list = _prefs?.getStringList(_prefix + AppConstants.prefsDietProfiles);
    return PreferenceOptions.normalizeDietProfileKeys(list ?? const []);
  }

  Future<void> saveDietProfiles(List<String> values) async {
    await (await _p).setStringList(
      _prefix + AppConstants.prefsDietProfiles,
      List<String>.from(values),
    );
  }

  List<String> getAllergensAvoid() {
    final list = _prefs?.getStringList(_prefix + AppConstants.prefsAllergensAvoid);
    return PreferenceOptions.normalizeAllergenKeys(list ?? const []);
  }

  Future<void> saveAllergensAvoid(List<String> values) async {
    await (await _p).setStringList(
      _prefix + AppConstants.prefsAllergensAvoid,
      List<String>.from(values),
    );
  }

  String? getAllergyNotes() => getPreference(AppConstants.prefsAllergyNotes);

  Future<void> saveAllergyNotes(String? value) async {
    final p = await _p;
    const key = _prefix + AppConstants.prefsAllergyNotes;
    if (value == null || value.trim().isEmpty) {
      await p.remove(key);
    } else {
      await p.setString(key, value.trim());
    }
  }

  /// Hydrates lifestyle fields from GET get_user_profile after sign-in.
  /// Omitted list fields are stored as empty so stale device prefs do not skip onboarding.
  /// Set [applyAllergyNotes] when the user document includes `allergyNotes` (even if empty).
  Future<void> persistLifestyleFromBackend({
    List<String>? dietProfiles,
    List<String>? allergensAvoid,
    List<String>? preferredCuisines,
    String? allergyNotes,
    bool applyAllergyNotes = false,
  }) async {
    final p = await _p;
    if (dietProfiles != null) {
      await p.setStringList(
        _prefix + AppConstants.prefsDietProfiles,
        List<String>.from(dietProfiles),
      );
    }
    if (allergensAvoid != null) {
      await p.setStringList(
        _prefix + AppConstants.prefsAllergensAvoid,
        List<String>.from(allergensAvoid),
      );
    }
    if (preferredCuisines != null) {
      await p.setStringList(
        _prefix + AppConstants.prefsUsualCuisines,
        PreferenceOptions.normalizeCuisineKeys(preferredCuisines),
      );
    }
    if (applyAllergyNotes) {
      await saveAllergyNotes(allergyNotes);
    }
  }

  /// Clears structured lifestyle prefs (e.g. when switching accounts on one device).
  void clearLifestylePrefsSync() {
    _prefs?.remove(_prefix + AppConstants.prefsDietProfiles);
    _prefs?.remove(_prefix + AppConstants.prefsAllergensAvoid);
    _prefs?.remove(_prefix + AppConstants.prefsAllergyNotes);
    _prefs?.remove(_prefix + AppConstants.prefsUsualCuisines);
  }

  /// Chosen pantry / ingredient labels sent to POST generate-recipe.
  List<String> getIngredients() {
    final list = _prefs?.getStringList(_prefix + AppConstants.prefsIngredients);
    return list ?? const [];
  }

  /// Cuisines the user usually cooks (used to suggest pantry items on Home).
  List<String> getUsualCuisines() {
    final list =
        _prefs?.getStringList(_prefix + AppConstants.prefsUsualCuisines);
    return PreferenceOptions.normalizeCuisineKeys(list ?? const []);
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

  Future<void> saveUsualCuisines(List<String> cuisines) async {
    await (await _p).setStringList(
      _prefix + AppConstants.prefsUsualCuisines,
      cuisines,
    );
  }

  void saveUsualCuisinesSync(List<String> cuisines) {
    _prefs?.setStringList(
      _prefix + AppConstants.prefsUsualCuisines,
      cuisines,
    );
  }

  bool isGuestMode() =>
      _prefs?.getBool(_prefix + AppConstants.prefsGuestMode) ?? false;

  void setGuestModeSync(bool value) {
    _prefs?.setBool(_prefix + AppConstants.prefsGuestMode, value);
  }

  /// Import tab one-time tile coach (see [HomeShellScreen]).
  bool getImportHubCoachSeenSync() =>
      _prefs?.getBool(_prefix + AppConstants.prefsImportHubCoachSeen) ?? false;

  void setImportHubCoachSeenSync(bool value) {
    _prefs?.setBool(_prefix + AppConstants.prefsImportHubCoachSeen, value);
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
    const key = _prefix + AppConstants.prefsAnonymousId;
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
    const keyDay = _prefix + AppConstants.prefsGuestGenDayKey;
    const keyCount = _prefix + AppConstants.prefsGuestGenCount;
    final storedDay = p.getString(keyDay);
    int count = 0;
    if (storedDay == day) {
      count = p.getInt(keyCount) ?? 0;
    }
    await p.setString(keyDay, day);
    await p.setInt(keyCount, count + 1);
  }

  SubscriptionStatus readSubscriptionCacheSync() {
    final raw =
        _prefs?.getString(_prefix + AppConstants.prefsSubscriptionCache);
    if (raw == null || raw.isEmpty) return const SubscriptionStatus();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SubscriptionStatus.fromJson(map);
    } catch (_) {
      return const SubscriptionStatus();
    }
  }

  Future<void> saveSubscriptionCacheSync(SubscriptionStatus status) async {
    final p = await _p;
    await p.setString(
      _prefix + AppConstants.prefsSubscriptionCache,
      jsonEncode(status.toJson()),
    );
  }

  Future<void> clearSubscriptionCacheSync() async {
    final p = await _p;
    await p.remove(_prefix + AppConstants.prefsSubscriptionCache);
  }
}
