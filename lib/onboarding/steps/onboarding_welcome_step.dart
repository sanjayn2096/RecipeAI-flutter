import 'package:flutter/material.dart';

import '../../core/l10n_context.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_scaffold.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({
    super.key,
    required this.controller,
    required this.onContinue,
  });

  final OnboardingController controller;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingScaffold(
      currentStep: controller.stepIndex,
      totalSteps: OnboardingController.stepCount,
      stepLabel: l10n.onboardingStepLabel(
        controller.stepIndex + 1,
        OnboardingController.stepCount,
      ),
      title: l10n.onboardingWelcomeTitle,
      subtitle: l10n.onboardingWelcomeSubtitle,
      showBack: false,
      body: const SizedBox.shrink(),
      bottom: FilledButton(
        onPressed: onContinue,
        child: Text(l10n.onboardingWelcomeCta),
      ),
    );
  }
}
