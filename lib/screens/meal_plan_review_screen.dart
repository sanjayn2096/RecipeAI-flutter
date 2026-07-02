import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n_context.dart';
import '../core/grocery_retailer_handoff.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/meal_plan.dart';
import '../data/models/recipe.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/meal_plan_view_model.dart';

class MealPlanReviewScreen extends StatefulWidget {
  const MealPlanReviewScreen({
    super.key,
    required this.mealPlanViewModel,
    required this.groceryListViewModel,
    required this.appTelemetry,
  });

  final MealPlanViewModel mealPlanViewModel;
  final GroceryListViewModel groceryListViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<MealPlanReviewScreen> createState() => _MealPlanReviewScreenState();
}

class _MealPlanReviewScreenState extends State<MealPlanReviewScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.mealPlanViewModel.plan == null) {
      widget.mealPlanViewModel.loadCached();
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final wd = names[d.weekday - 1];
      return '$wd ${d.month}/${d.day}';
    } catch (_) {
      return iso;
    }
  }

  String _mealLabel(BuildContext context, String meal) {
    switch (meal) {
      case 'breakfast':
        return context.l10n.mealPlanBreakfast;
      case 'lunch':
        return context.l10n.mealPlanLunch;
      default:
        return context.l10n.mealPlanDinner;
    }
  }

  Future<void> _regenerate(String date, String meal) async {
    final ok = await widget.mealPlanViewModel.regenerateSlot(
      date: date,
      meal: meal,
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.mealPlanViewModel.error ?? 'Could not regenerate',
          ),
        ),
      );
    }
  }

  Future<void> _addToGrocery() async {
    final lines = widget.mealPlanViewModel.selectedMissingGroceryLines();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items to add')),
      );
      return;
    }
    await widget.groceryListViewModel.addMergedLinesFromMealPlan(
      lines: lines,
      planId: widget.mealPlanViewModel.plan?.planId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.recipeAddedToGroceryList)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.mealPlanViewModel,
      builder: (context, _) {
        final plan = widget.mealPlanViewModel.plan;
        if (widget.mealPlanViewModel.loading && plan == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.mealPlanTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.mealPlanTitle)),
            body: Center(
              child: TextButton(
                onPressed: () => context.go('/meal-plan/wizard'),
                child: Text(context.l10n.mealPlanStartNew),
              ),
            ),
          );
        }

        final cost = plan.costSummary;
        final missing = widget.mealPlanViewModel.missingIngredients;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.mealPlanTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'New plan',
                onPressed: widget.mealPlanViewModel.loading
                    ? null
                    : () => context.push('/meal-plan/wizard'),
              ),
            ],
          ),
          body: widget.mealPlanViewModel.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (plan.assistantMessage != null &&
                        plan.assistantMessage!.isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(plan.assistantMessage!),
                        ),
                      ),
                    _BudgetBanner(cost: cost),
                    const SizedBox(height: 8),
                    ...plan.days.map((day) => _DaySection(
                          day: day,
                          formatDate: _formatDate,
                          mealLabel: (meal) => _mealLabel(context, meal),
                          onRegenerate: _regenerate,
                          onViewRecipe: (recipe) {
                            context.push('/show-recipe', extra: {
                              'recipe': recipe,
                            });
                          },
                        )),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.mealPlanMissingTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...missing.asMap().entries.map(
                          (e) => CheckboxListTile(
                            value: e.value.selected,
                            onChanged: (v) => widget.mealPlanViewModel
                                .toggleMissingSelected(e.key, v ?? false),
                            title: Text(e.value.name),
                            subtitle: e.value.estimatedUsd > 0
                                ? Text(
                                    '\$${e.value.estimatedUsd.toStringAsFixed(2)}',
                                  )
                                : null,
                          ),
                        ),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: _addToGrocery,
                    child: Text(context.l10n.mealPlanAddToGrocery),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await CopyListHandoff(
                              widget.mealPlanViewModel
                                  .selectedMissingGroceryLines(),
                            ).execute(context);
                            await widget.appTelemetry.logFeatureInteraction(
                              featureId: FeatureIds.mealPlanCopyList,
                            );
                          },
                          child: Text(context.l10n.mealPlanCopyList),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await InstacartHandoff().execute(context);
                            await widget.appTelemetry.logFeatureInteraction(
                              featureId: FeatureIds.mealPlanInstacartSoon,
                            );
                          },
                          child: Text(context.l10n.mealPlanShopInstacart),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BudgetBanner extends StatelessWidget {
  const _BudgetBanner({required this.cost});

  final MealPlanCostSummary cost;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final over = !cost.withinBudget;
    return Card(
      color: over ? scheme.errorContainer : scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.mealPlanBudgetSummary,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '\$${cost.estimatedTotalUsd.toStringAsFixed(2)}'
              '${cost.budgetUsd != null ? ' / \$${cost.budgetUsd!.toStringAsFixed(0)} budget' : ''}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.l10n.mealPlanOverBudget,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.formatDate,
    required this.mealLabel,
    required this.onRegenerate,
    required this.onViewRecipe,
  });

  final MealPlanDay day;
  final String Function(String) formatDate;
  final String Function(String) mealLabel;
  final Future<void> Function(String date, String meal) onRegenerate;
  final void Function(Recipe recipe) onViewRecipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            formatDate(day.date),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...day.slots.map(
          (slot) => ListTile(
            title: Text(slot.recipe.recipeName),
            subtitle: Text('${mealLabel(slot.meal)} · ${slot.recipe.cuisine}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'view') {
                  onViewRecipe(slot.recipe);
                } else if (v == 'regen') {
                  onRegenerate(day.date, slot.meal);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'view',
                  child: Text(context.l10n.mealPlanViewRecipe),
                ),
                PopupMenuItem(
                  value: 'regen',
                  child: Text(context.l10n.mealPlanRegenerate),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
