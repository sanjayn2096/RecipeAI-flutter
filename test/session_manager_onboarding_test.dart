import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recipe_ai/data/models/recipe_generation_usage.dart';
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

    test('diet profile does not imply onboardingComplete', () async {
      await session.saveUserId('user-a');
      await session.saveDietProfiles(['vegan']);
      expect(session.getOnboardingCompleteSync(), isFalse);
    });

    test('clearing lifestyle prefs does not clear onboardingComplete',
        () async {
      await session.saveUserId('user-a');
      session.setOnboardingCompleteSync(true);
      await session.saveDietProfiles(['vegan']);
      await session.saveAllergensAvoid(['peanut']);
      await session.saveUsualCuisines(['indian']);

      session.clearLifestylePrefsSync();

      expect(session.getOnboardingCompleteSync(), isTrue);
      expect(session.getDietProfiles(), isEmpty);
      expect(session.getAllergensAvoid(), isEmpty);
      expect(session.getUsualCuisines(), isEmpty);
    });

    test('signed-in recipe usage uses in-memory backend snapshot', () async {
      final today = RecipeGenerationUsage.utcDayKeyNow();
      session.updateSignedInRecipeGenerationUsage(
        RecipeGenerationUsage(utcDay: today, count: 2, dailyLimit: 3),
      );

      await session.recordSignedInFreeRecipeGenerationSuccess(isPremium: false);

      final usage = session.getSignedInRecipeGenerationUsageForTodaySync();
      expect(usage.count, 3);
      expect(usage.dailyLimit, 3);
    });
  });
}
