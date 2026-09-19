import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../onboarding/onboarding_session_extension.dart';
import '../services/session_manager.dart';
import '../view_models/login_view_model.dart';
import 'pending_deep_link.dart';
import 'pending_shared_import.dart';

/// Routes after splash, login, signup, or email verification.
Future<void> navigateAfterAuthentication(
  BuildContext context, {
  required SessionManager sessionManager,
  required LoginViewModel loginViewModel,
}) async {
  final pendingShare = PendingSharedImport.peek();
  if (pendingShare != null && !sessionManager.isGuestMode()) {
    if (context.mounted) context.go('/import-shared');
    return;
  }
  if (pendingShare != null && sessionManager.isGuestMode()) {
    // Import requires a signed-in account; drop the share if they continue as guest.
    PendingSharedImport.clear();
  }
  final pending = PendingDeepLink.take();
  if (pending != null && pending.startsWith('/r/')) {
    if (context.mounted) context.go(pending);
    return;
  }
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
