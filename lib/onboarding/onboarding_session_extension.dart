import '../services/session_manager.dart';
import 'onboarding_prefs.dart';

/// Onboarding helpers on [SessionManager] without modifying the core class.
extension OnboardingSessionManager on SessionManager {
  bool getOnboardingCompleteSync() {
    final userId = getUserId();
    if (userId == null || userId.isEmpty) return false;
    if (getPreference(OnboardingPrefs.onboardingComplete) != 'true') {
      return false;
    }
    final completedFor =
        getPreference(OnboardingPrefs.onboardingCompleteUserId);
    if (completedFor == null || completedFor.isEmpty) {
      // Legacy device flag from before per-user scoping — bind to this account.
      savePreferenceSync(OnboardingPrefs.onboardingCompleteUserId, userId);
      return true;
    }
    return completedFor == userId;
  }

  void setOnboardingCompleteSync(bool value) {
    savePreferenceSync(
      OnboardingPrefs.onboardingComplete,
      value ? 'true' : 'false',
    );
    if (value) {
      final userId = getUserId();
      if (userId != null && userId.isNotEmpty) {
        savePreferenceSync(
          OnboardingPrefs.onboardingCompleteUserId,
          userId,
        );
      }
    } else {
      savePreferenceSync(OnboardingPrefs.onboardingCompleteUserId, '');
    }
  }

  void clearOnboardingStateSync() {
    setOnboardingCompleteSync(false);
  }

  bool getFirstPromptHintSeenSync() =>
      getPreference(OnboardingPrefs.firstPromptHintSeen) == 'true';

  void setFirstPromptHintSeenSync(bool value) {
    savePreferenceSync(
      OnboardingPrefs.firstPromptHintSeen,
      value ? 'true' : 'false',
    );
  }

  bool hasExistingLifestyleProfile() {
    return getDietProfiles().isNotEmpty ||
        getAllergensAvoid().isNotEmpty ||
        getUsualCuisines().isNotEmpty;
  }

  void migrateOnboardingCompleteIfExistingUser() {
    if (getOnboardingCompleteSync()) return;
    if (hasExistingLifestyleProfile()) {
      setOnboardingCompleteSync(true);
    }
  }

  Future<bool> isSignedInFreeRecipeQuotaExceededForToday({
    required bool isPremium,
  }) async {
    if (isPremium || isGuestMode()) return false;
    final day = SessionManager.guestQuotaUtcDayKeyNow();
    final storedDay = getPreference(OnboardingPrefs.freeGenDayKey);
    if (storedDay != day) return false;
    final raw = getPreference(OnboardingPrefs.freeGenCount);
    final n = int.tryParse(raw ?? '') ?? 0;
    return n >= OnboardingPrefs.freeTierDailyRecipeLimit;
  }

  Future<void> recordSignedInFreeRecipeGenerationSuccess({
    required bool isPremium,
  }) async {
    if (isPremium || isGuestMode()) return;
    final day = SessionManager.guestQuotaUtcDayKeyNow();
    final storedDay = getPreference(OnboardingPrefs.freeGenDayKey);
    var count = 0;
    if (storedDay == day) {
      count = int.tryParse(getPreference(OnboardingPrefs.freeGenCount) ?? '') ?? 0;
    }
    savePreferenceSync(OnboardingPrefs.freeGenDayKey, day);
    savePreferenceSync(
      OnboardingPrefs.freeGenCount,
      '${count + 1}',
    );
  }
}
