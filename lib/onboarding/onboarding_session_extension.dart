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

  int getSignedInFreeImportCountForTodaySync() {
    if (isGuestMode()) return 0;
    final day = SessionManager.guestQuotaUtcDayKeyNow();
    final storedDay = getPreference(OnboardingPrefs.importDayKey);
    if (storedDay != day) return 0;
    return int.tryParse(getPreference(OnboardingPrefs.importCount) ?? '') ?? 0;
  }

  Future<bool> isSignedInFreeImportQuotaExceededForToday({
    required bool isPremium,
  }) async {
    if (isPremium || isGuestMode()) return false;
    return getSignedInFreeImportCountForTodaySync() >=
        OnboardingPrefs.freeTierDailyImportLimit;
  }

  Future<void> recordSignedInFreeImportSuccess({
    required bool isPremium,
  }) async {
    if (isPremium || isGuestMode()) return;
    final day = SessionManager.guestQuotaUtcDayKeyNow();
    final storedDay = getPreference(OnboardingPrefs.importDayKey);
    var count = 0;
    if (storedDay == day) {
      count =
          int.tryParse(getPreference(OnboardingPrefs.importCount) ?? '') ?? 0;
    }
    savePreferenceSync(OnboardingPrefs.importDayKey, day);
    savePreferenceSync(
      OnboardingPrefs.importCount,
      '${count + 1}',
    );
    notifyUsageQuotaChanged();
  }
}
