import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/core/preference_options.dart';
import 'package:recipe_ai/onboarding/onboarding_controller.dart';

void main() {
  group('OnboardingController', () {
    late OnboardingController controller;

    setUp(() {
      controller = OnboardingController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('welcome step always allows continue', () {
      expect(controller.stepIndex, 0);
      expect(controller.canContinue, isTrue);
    });

    test('diet step requires at least one selection', () {
      controller.nextStep();
      expect(controller.stepIndex, 1);
      expect(controller.canContinue, isFalse);

      controller.toggleDiet(PreferenceOptions.dietVegan);
      expect(controller.canContinue, isTrue);
    });

    test('no restrictions clears other diet selections', () {
      controller.nextStep();
      controller.toggleDiet(PreferenceOptions.dietVegan);
      controller.toggleDiet(PreferenceOptions.dietNoRestrictions);

      expect(controller.dietProfiles, {PreferenceOptions.dietNoRestrictions});
    });

    test('cuisines limited to three', () {
      controller.nextStep(); // welcome
      controller.toggleDiet(PreferenceOptions.dietVegan);
      controller.nextStep(); // diet
      controller.nextStep(); // allergies
      expect(controller.stepIndex, 3);

      controller.toggleCuisine(PreferenceOptions.cuisineIndian);
      controller.toggleCuisine(PreferenceOptions.cuisineMexican);
      controller.toggleCuisine(PreferenceOptions.cuisineChinese);
      expect(controller.usualCuisines.length, 3);
      expect(controller.cuisineAtLimit(PreferenceOptions.cuisineThai), isTrue);

      controller.toggleCuisine(PreferenceOptions.cuisineThai);
      expect(
        controller.usualCuisines.contains(PreferenceOptions.cuisineThai),
        isFalse,
      );
    });

    test('allergies step always allows continue', () {
      controller.nextStep(); // welcome
      controller.toggleDiet(PreferenceOptions.dietVegan);
      controller.nextStep(); // diet
      expect(controller.stepIndex, 2);
      expect(controller.canContinue, isTrue);
    });

    test('previousStep does not leave welcome', () {
      controller.previousStep();
      expect(controller.stepIndex, 0);
    });
  });
}
