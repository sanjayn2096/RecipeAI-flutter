import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_context.dart';
import '../core/telemetry/app_telemetry.dart';

enum GuestLimitAction { dismiss, signUp, premium }

enum FreeTierLimitAction { dismiss, premium }

/// Shown when a guest hits the daily free recipe generation cap.
Future<GuestLimitAction?> showGuestRecipeLimitReachedDialog(
  BuildContext context, {
  AppTelemetry? appTelemetry,
}) {
  return showDialog<GuestLimitAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Free limit reached'),
      content: const Text(
        'You’ve used your free recipe generations for today. Sign up for a free account or upgrade to Premium for unlimited recipes and no ads.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(GuestLimitAction.dismiss),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () {
            if (appTelemetry != null) {
              appTelemetry.logPremiumCtaTap(source: 'guest_quota_dialog');
            }
            Navigator.of(ctx).pop(GuestLimitAction.premium);
          },
          child: const Text('Go Premium'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(GuestLimitAction.signUp),
          child: const Text('Sign up'),
        ),
      ],
    ),
  );
}

/// Shown when a guest tries to import a recipe. Returns `true` if user chose Sign up.
Future<bool?> showGuestImportSignupDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign up'),
      content: const Text(
        'Sign in to import recipes from links, pasted text, or cookbook photos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Dismiss'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign up'),
        ),
      ],
    ),
  );
}

/// Shown when a guest tries to use favorites. Returns `true` if user chose Sign up.
Future<bool?> showGuestFavoriteSignupDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Sign up'),
      content: const Text(
        'Sign up to create and access your favorite recipes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Dismiss'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign up'),
        ),
      ],
    ),
  );
}

/// Shown when a signed-in free user hits the daily recipe generation cap.
Future<FreeTierLimitAction?> showFreeTierRecipeLimitReachedDialog(
  BuildContext context, {
  AppTelemetry? appTelemetry,
}) {
  final l10n = context.l10n;
  return showDialog<FreeTierLimitAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.freeTierQuotaDialogTitle),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(l10n.freeTierQuotaMessage)),
          const SizedBox(width: 8),
          Tooltip(
            message: l10n.freeTierQuotaResetInfo,
            child: IconButton(
              tooltip: l10n.freeTierQuotaResetInfo,
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog<void>(
                  context: ctx,
                  builder: (infoCtx) => AlertDialog(
                    title: Text(l10n.freeTierQuotaResetTitle),
                    content: Text(l10n.freeTierQuotaResetInfo),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(infoCtx).pop(),
                        child: Text(l10n.ok),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(FreeTierLimitAction.dismiss),
          child: Text(l10n.notNow),
        ),
        FilledButton(
          onPressed: () {
            if (appTelemetry != null) {
              appTelemetry.logPremiumCtaTap(source: 'free_quota_dialog');
            }
            Navigator.of(ctx).pop(FreeTierLimitAction.premium);
          },
          child: Text(l10n.goPremium),
        ),
      ],
    ),
  );
}

/// Navigate to auth with the sign-up form open.
void goToSignup(BuildContext context) {
  context.go('/login', extra: true);
}
