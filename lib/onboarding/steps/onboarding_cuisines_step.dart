import 'package:flutter/material.dart';

import '../../core/l10n_context.dart';
import '../../core/l10n_extensions.dart';
import '../../core/preference_options.dart';
import '../onboarding_controller.dart';
import '../widgets/animated_cuisine_card.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

class OnboardingCuisinesStep extends StatelessWidget {
  const OnboardingCuisinesStep({
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
    final keys = PreferenceOptions.cuisineKeys;
    final count = controller.usualCuisines.length;
    return OnboardingScaffold(
      currentStep: controller.stepIndex,
      totalSteps: OnboardingController.stepCount,
      stepLabel: l10n.onboardingStepLabel(
        controller.stepIndex + 1,
        OnboardingController.stepCount,
      ),
      title: l10n.onboardingCuisinesTitle,
      subtitle: l10n.onboardingCuisinesSubtitle,
      onBack: onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              l10n.onboardingCuisinesSelectedCount(count, OnboardingController.maxCuisines),
              key: ValueKey(count),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemCount: keys.length,
            itemBuilder: (context, i) {
              final key = keys[i];
              final selected = controller.usualCuisines.contains(key);
              final atLimit = controller.cuisineAtLimit(key);
              return StaggeredEntrance(
                index: i,
                child: AnimatedCuisineCard(
                  emoji: cuisineEmojiForKey(key),
                  label: l10n.cuisineLabel(key),
                  selected: selected,
                  enabled: selected || !atLimit,
                  onTap: () => controller.toggleCuisine(key),
                ),
              );
            },
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
