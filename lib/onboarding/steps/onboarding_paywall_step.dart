import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../../core/l10n_context.dart';
import '../../core/monetization_config.dart';
import '../../core/telemetry/app_telemetry.dart';
import '../../core/telemetry/feature_ids.dart';
import '../../view_models/subscription_view_model.dart';
import '../../widgets/sous_chef_brand.dart';
import '../../widgets/tier_comparison_table.dart';
import '../onboarding_controller.dart';
import '../widgets/onboarding_progress_bar.dart';

class OnboardingPaywallStep extends StatefulWidget {
  const OnboardingPaywallStep({
    super.key,
    required this.controller,
    required this.subscriptionViewModel,
    required this.appTelemetry,
    required this.onComplete,
  });

  final OnboardingController controller;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;
  final Future<void> Function({required bool subscribed}) onComplete;

  @override
  State<OnboardingPaywallStep> createState() => _OnboardingPaywallStepState();
}

class _OnboardingPaywallStepState extends State<OnboardingPaywallStep> {
  bool _loggedView = false;

  @override
  void initState() {
    super.initState();
    widget.subscriptionViewModel.addListener(_onSubscriptionUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_loggedView) {
        _loggedView = true;
        widget.appTelemetry.logPremiumPaywallView(source: 'onboarding');
      }
    });
  }

  @override
  void dispose() {
    widget.subscriptionViewModel.removeListener(_onSubscriptionUpdate);
    super.dispose();
  }

  void _onSubscriptionUpdate() {
    if (widget.subscriptionViewModel.isPremium && mounted) {
      unawaited(widget.onComplete(subscribed: true));
    }
  }

  Future<void> _onSubscribe() async {
    await widget.appTelemetry.logPremiumSubscribeTap(
      source: 'onboarding',
      productId: MonetizationConfig.standardProductId,
    );
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.onboardingPaywallSubscribe,
    );
    await widget.subscriptionViewModel.subscribe(source: 'onboarding');
  }

  Future<void> _onSkip() async {
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.onboardingPaywallSkip,
    );
    await widget.onComplete(subscribed: false);
  }

  Future<void> _onRestore() async {
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.premiumRestore,
      action: 'onboarding',
    );
    await widget.subscriptionViewModel.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vm = widget.subscriptionViewModel;
    final price = vm.product?.price ?? MonetizationConfig.monthlyPriceDisplay;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: kToolbarHeight,
              child: Center(child: SousChefInlineTitle(markSize: 44)),
            ),
            OnboardingProgressBar(
              currentStep: widget.controller.stepIndex,
              totalSteps: OnboardingController.stepCount,
              stepLabel: l10n.onboardingStepLabel(
                widget.controller.stepIndex + 1,
                OnboardingController.stepCount,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.onboardingPaywallTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.onboardingPaywallSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                    ),
                    const SizedBox(height: 20),
                    const TierComparisonTable(compact: true),
                    if (vm.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        vm.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: vm.loading ? null : _onSubscribe,
              child: vm.loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.onboardingPaywallSubscribe(price)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: vm.loading ? null : _onSkip,
              child: Text(l10n.onboardingPaywallSkip),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.loading ? null : _onRestore,
              child: Text(l10n.onboardingPaywallRestore),
            ),
          ],
        ),
      ),
    );
  }
}
