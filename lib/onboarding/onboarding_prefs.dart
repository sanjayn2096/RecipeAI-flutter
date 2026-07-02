/// Preference keys for onboarding (mirrors [AppConstants] when integrated).
abstract final class OnboardingPrefs {
  static const onboardingComplete = 'onboardingComplete';
  static const onboardingCompleteUserId = 'onboardingCompleteUserId';
  static const firstPromptHintSeen = 'firstPromptHintSeen';
  static const freeGenDayKey = 'freeGenDayKey';
  static const freeGenCount = 'freeGenCount';
  static const freeTierDailyRecipeLimit = 3;
  static const importDayKey = 'importDayKey';
  static const importCount = 'importCount';
  static const freeTierDailyImportLimit = 1;
}
