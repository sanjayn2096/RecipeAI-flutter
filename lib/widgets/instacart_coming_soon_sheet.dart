import 'package:flutter/material.dart';

import '../core/app_strings.dart';

Future<void> showInstacartComingSoonSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.mealPlanInstacartTitle,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.mealPlanInstacartBody,
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    },
  );
}
