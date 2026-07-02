import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/l10n_context.dart';
import '../../widgets/sous_chef_brand.dart';
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
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Opacity(
                opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Column(
              children: [
                const SousChefInlineTitle(markSize: 56),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/cooking_animation.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: onContinue,
        child: Text(l10n.onboardingWelcomeCta),
      ),
    );
  }
}
