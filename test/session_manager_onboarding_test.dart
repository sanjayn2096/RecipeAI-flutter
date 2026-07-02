import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipe_ai/onboarding/onboarding_prefs.dart';
import 'package:recipe_ai/onboarding/onboarding_session_extension.dart';
import 'package:recipe_ai/services/session_manager.dart';

void main() {
  group('SessionManager onboarding', () {
    late SessionManager session;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      session = SessionManager(prefs: prefs);
    });

    test('onboardingComplete defaults false', () {
      expect(session.getOnboardingCompleteSync(), isFalse);
    });

    test('onboardingComplete is scoped to userId', () async {
      await session.saveUserId('user-a');
      session.setOnboardingCompleteSync(true);
      expect(session.getOnboardingCompleteSync(), isTrue);

      await session.saveUserId('user-b');
      expect(session.getOnboardingCompleteSync(), isFalse);
    });

    test('legacy onboardingComplete binds to current userId', () async {
      await session.saveUserId('user-a');
      session.savePreferenceSync(OnboardingPrefs.onboardingComplete, 'true');
      expect(session.getOnboardingCompleteSync(), isTrue);
      expect(
        session.getPreference(OnboardingPrefs.onboardingCompleteUserId),
        'user-a',
      );
    });

    test('migrateOnboardingCompleteIfExistingUser when diet saved', () async {
      await session.saveUserId('user-a');
      await session.saveDietProfiles(['vegan']);
      session.migrateOnboardingCompleteIfExistingUser();
      expect(session.getOnboardingCompleteSync(), isTrue);
    });

    test('free tier quota resets on new UTC day', () async {
      await session.recordSignedInFreeRecipeGenerationSuccess(isPremium: false);
      final exceeded = await session.isSignedInFreeRecipeQuotaExceededForToday(
        isPremium: false,
      );
      expect(exceeded, isFalse);
    });
  });
}
