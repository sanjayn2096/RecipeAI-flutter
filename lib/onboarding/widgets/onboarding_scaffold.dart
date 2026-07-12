import 'package:flutter/material.dart';

import '../../widgets/sous_chef_brand.dart';
import 'onboarding_progress_bar.dart';

/// Shared layout for onboarding preference steps.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabel,
    required this.title,
    this.subtitle,
    required this.body,
    this.showBack = true,
    this.onBack,
    this.bottom,
  });

  final int currentStep;
  final int totalSteps;
  final String stepLabel;
  final String title;
  final String? subtitle;
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(child: SousChefInlineTitle(markSize: 44)),
                      if (showBack && onBack != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: MaterialLocalizations.of(context)
                                .backButtonTooltip,
                            onPressed: onBack,
                          ),
                        ),
                    ],
                  ),
                ),
                OnboardingProgressBar(
                  currentStep: currentStep,
                  totalSteps: totalSteps,
                  stepLabel: stepLabel,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  body,
                ],
              ),
            ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: bottom!,
            ),
        ],
      ),
    );
  }
}
