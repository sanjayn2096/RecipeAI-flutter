import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../onboarding/onboarding_session_extension.dart';
import '../services/session_manager.dart';
import '../view_models/login_view_model.dart';

/// Routes after splash, login, signup, or email verification.
Future<void> navigateAfterAuthentication(
  BuildContext context, {
  required SessionManager sessionManager,
  required LoginViewModel loginViewModel,
}) async {
  if (sessionManager.isGuestMode()) {
    if (context.mounted) context.go('/home');
    return;
  }
  await loginViewModel.prepareOnboardingRoutingState();
  if (!context.mounted) return;
  if (!sessionManager.getOnboardingCompleteSync()) {
    context.go('/onboarding');
  } else {
    context.go('/home');
  }
}
