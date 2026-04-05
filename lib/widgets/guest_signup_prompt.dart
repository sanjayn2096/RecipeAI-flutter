import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown when a guest hits the daily free recipe generation cap. Returns `true` if user chose Sign up.
Future<bool?> showGuestRecipeLimitReachedDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Free limit reached'),
      content: const Text(
        'You’ve used your free recipe generations for today. Create an account to keep generating recipes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Not now'),
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

/// Navigate to auth with the sign-up form open.
void goToSignup(BuildContext context) {
  context.go('/login', extra: true);
}
