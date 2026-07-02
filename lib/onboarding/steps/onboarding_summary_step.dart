import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/l10n_context.dart';
import '../../core/l10n_extensions.dart';
import '../../core/preference_options.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

class OnboardingSummaryStep extends StatelessWidget {
  const OnboardingSummaryStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onContinue,
  });

  final OnboardingController controller;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  String _dietSummary(BuildContext context) {
    final l10n = context.l10n;
    if (controller.dietProfiles.contains(PreferenceOptions.dietNoRestrictions)) {
      return l10n.dietLabel(PreferenceOptions.dietNoRestrictions);
    }
    return controller.dietProfiles.map(l10n.dietLabel).join(' · ');
  }

  String _allergySummary(BuildContext context) {
    final l10n = context.l10n;
    if (controller.allergensAvoid.isEmpty) {
      return l10n.onboardingSummaryNoAllergens;
    }
    return controller.allergensAvoid.map(l10n.allergenLabel).join(' · ');
  }

  String _cuisineSummary(BuildContext context) {
    final l10n = context.l10n;
    return controller.usualCuisines.map(l10n.cuisineLabel).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final lines = [
      l10n.onboardingSummaryDietLine(_dietSummary(context)),
      l10n.onboardingSummaryAllergiesLine(_allergySummary(context)),
      l10n.onboardingSummaryCuisinesLine(_cuisineSummary(context)),
    ];
    return OnboardingScaffold(
      currentStep: controller.stepIndex,
      totalSteps: OnboardingController.stepCount,
      stepLabel: l10n.onboardingStepLabel(
        controller.stepIndex + 1,
        OnboardingController.stepCount,
      ),
      title: l10n.onboardingSummaryTitle,
      subtitle: l10n.onboardingSummarySubtitle,
      onBack: onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines.length; i++)
            StaggeredEntrance(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: scheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lines[i],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          StaggeredEntrance(
            index: 3,
            child: Shimmer.fromColors(
              baseColor: scheme.surfaceContainerHighest,
              highlightColor: scheme.surface,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingSummaryPreviewHint,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.onboardingSummaryPreviewPlaceholder,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: onContinue,
        child: Text(l10n.next),
      ),
    );
  }
}
