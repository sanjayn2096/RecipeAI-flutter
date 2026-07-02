import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../core/preference_options.dart';
import 'onboarding_session_extension.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../services/session_manager.dart';
import '../view_models/home_view_model.dart';
import '../view_models/subscription_view_model.dart';
import 'onboarding_controller.dart';
import 'steps/onboarding_allergies_step.dart';
import 'steps/onboarding_cuisines_step.dart';
import 'steps/onboarding_diet_step.dart';
import 'steps/onboarding_paywall_step.dart';
import 'steps/onboarding_summary_step.dart';
import 'steps/onboarding_welcome_step.dart';

/// Six-step preference onboarding ending in a soft premium upsell.
class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({
    super.key,
    required this.sessionManager,
    required this.homeViewModel,
    required this.subscriptionViewModel,
    required this.appTelemetry,
  });

  final SessionManager sessionManager;
  final HomeViewModel homeViewModel;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final OnboardingController _controller;
  late final PageController _pageController;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController();
    _pageController = PageController();
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (_pageController.hasClients &&
        _pageController.page?.round() != _controller.stepIndex) {
      _pageController.animateToPage(
        _controller.stepIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) setState(() {});
  }

  void _advance() {
    if (_controller.stepIndex == 4) {
      unawaited(_persistPreferences());
    }
    _controller.nextStep();
  }

  Future<void> _persistPreferences() async {
    final diets = _controller.dietProfiles.toList();
    final noRestrictions = diets.contains(PreferenceOptions.dietNoRestrictions);
    widget.sessionManager.savePreferenceSync(
      AppConstants.prefsLifestyleDietRestrictions,
      noRestrictions
          ? PreferenceOptions.dietNoRestrictions
          : PreferenceOptions.noDietRestrictions,
    );
    await widget.homeViewModel.saveLifestyleProfile(
      dietProfiles: diets,
      allergensAvoid: _controller.allergensAvoid.toList(),
      allergyNotes: _controller.allergyNotes.trim().isEmpty
          ? null
          : _controller.allergyNotes.trim(),
    );
    widget.sessionManager.saveUsualCuisinesSync(
      _controller.usualCuisines.toList(),
    );
    if (_controller.usualCuisines.isNotEmpty) {
      widget.sessionManager.savePreferenceSync(
        AppConstants.prefsLifestyleCuisine,
        _controller.usualCuisines.first,
      );
    }
    await widget.homeViewModel.syncLifestyleFromPrefs();
  }

  Future<void> _finishOnboarding({required bool subscribed}) async {
    if (_completing) return;
    _completing = true;
    if (_controller.stepIndex < 4) {
      await _persistPreferences();
    }
    await widget.homeViewModel.markOnboardingComplete();
    widget.sessionManager.setFirstPromptHintSeenSync(false);
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.onboardingComplete,
      action: subscribed ? 'subscribed' : 'skipped_paywall',
    );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              OnboardingWelcomeStep(
                controller: _controller,
                onContinue: _advance,
              ),
              OnboardingDietStep(
                controller: _controller,
                onBack: _controller.previousStep,
                onContinue: _advance,
              ),
              OnboardingAllergiesStep(
                controller: _controller,
                onBack: _controller.previousStep,
                onContinue: _advance,
              ),
              OnboardingCuisinesStep(
                controller: _controller,
                onBack: _controller.previousStep,
                onContinue: _advance,
              ),
              OnboardingSummaryStep(
                controller: _controller,
                onBack: _controller.previousStep,
                onContinue: _advance,
              ),
              OnboardingPaywallStep(
                controller: _controller,
                subscriptionViewModel: widget.subscriptionViewModel,
                appTelemetry: widget.appTelemetry,
                onComplete: _finishOnboarding,
              ),
            ],
          ),
        );
      },
    );
  }
}
