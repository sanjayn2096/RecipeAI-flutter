import 'package:flutter/material.dart';

import '../../core/l10n_context.dart';
import '../../core/l10n_extensions.dart';
import '../../core/preference_options.dart';
import '../onboarding_controller.dart';
import '../widgets/animated_preference_chip.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

class OnboardingDietStep extends StatelessWidget {
  const OnboardingDietStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onContinue,
  });

  final OnboardingController controller;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keys = [
      ...PreferenceOptions.dietMultiSelectKeys,
      PreferenceOptions.dietNoRestrictions,
    ];
    return OnboardingScaffold(
      currentStep: controller.stepIndex,
      totalSteps: OnboardingController.stepCount,
      stepLabel: l10n.onboardingStepLabel(
        controller.stepIndex + 1,
        OnboardingController.stepCount,
      ),
      title: l10n.onboardingDietTitle,
      subtitle: l10n.onboardingDietSubtitle,
      onBack: onBack,
      body: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < keys.length; i++)
            StaggeredEntrance(
              index: i,
              child: AnimatedPreferenceChip(
                label: l10n.dietLabel(keys[i]),
                selected: controller.dietProfiles.contains(keys[i]),
                onTap: () => controller.toggleDiet(keys[i]),
              ),
            ),
        ],
      ),
      bottom: FilledButton(
        onPressed: controller.canContinue ? onContinue : null,
        child: Text(l10n.next),
      ),
    );
  }
}
