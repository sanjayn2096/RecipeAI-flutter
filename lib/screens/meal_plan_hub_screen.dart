import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_context.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../view_models/meal_plan_view_model.dart';

class MealPlanHubScreen extends StatefulWidget {
  const MealPlanHubScreen({
    super.key,
    required this.mealPlanViewModel,
    required this.appTelemetry,
  });

  final MealPlanViewModel mealPlanViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<MealPlanHubScreen> createState() => _MealPlanHubScreenState();
}

class _MealPlanHubScreenState extends State<MealPlanHubScreen> {
  @override
  void initState() {
    super.initState();
    widget.mealPlanViewModel.loadCached();
    unawaited(
      widget.appTelemetry.logFeatureInteraction(
        featureId: FeatureIds.mealPlanOpen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.mealPlanViewModel,
      builder: (context, _) {
        final hasPlan = widget.mealPlanViewModel.plan != null;
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.mealPlanTitle)),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.mealPlanHubSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/meal-plan/wizard'),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(context.l10n.mealPlanStartNew),
                ),
                if (hasPlan) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/meal-plan/review'),
                    icon: const Icon(Icons.restaurant_menu_outlined),
                    label: Text(context.l10n.mealPlanResume),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
