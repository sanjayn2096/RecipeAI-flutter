import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/monetization_navigation.dart';
import '../core/pantry_items.dart';
import '../core/telemetry/app_telemetry.dart';
import '../data/models/meal_plan.dart';
import '../services/session_manager.dart';
import '../view_models/meal_plan_view_model.dart';
import '../view_models/subscription_view_model.dart';

class MealPlanWizardScreen extends StatefulWidget {
  const MealPlanWizardScreen({
    super.key,
    required this.mealPlanViewModel,
    required this.subscriptionViewModel,
    required this.sessionManager,
    required this.appTelemetry,
  });

  final MealPlanViewModel mealPlanViewModel;
  final SubscriptionViewModel subscriptionViewModel;
  final SessionManager sessionManager;
  final AppTelemetry appTelemetry;

  @override
  State<MealPlanWizardScreen> createState() => _MealPlanWizardScreenState();
}

class _MealPlanWizardScreenState extends State<MealPlanWizardScreen> {
  int _step = 0;
  final _dietGoals = <String>{};
  final _cuisines = <String>{};
  final _mealSlots = <String>{'dinner'};
  final _weekdays = <int>{1, 2, 3};
  final _ingredients = <String>[];
  final _pantryController = TextEditingController();
  final _budgetController = TextEditingController(text: '85');
  final _customDietController = TextEditingController();

  static const _dietChips = [
    'High Protein',
    'Keto',
    'Paleo'
    'Balanced',
    'Gut-Friendly',
  ];

  static const _cuisineChips = [
    'Indian',
    'Italian',
    'Mexican',
    'Mediterranean',
    'Chinese',
    'American',
    'Thai',
    'Japanese',
  ];

  static const _weekdayMeta = [
    (1, AppStrings.mealPlanMon),
    (2, AppStrings.mealPlanTue),
    (3, AppStrings.mealPlanWed),
    (4, AppStrings.mealPlanThu),
    (5, AppStrings.mealPlanFri),
    (6, AppStrings.mealPlanSat),
    (7, AppStrings.mealPlanSun),
  ];

  @override
  void initState() {
    super.initState();
    final saved = widget.sessionManager.getIngredients();
    _ingredients.addAll(saved);
  }

  @override
  void dispose() {
    _pantryController.dispose();
    _budgetController.dispose();
    _customDietController.dispose();
    super.dispose();
  }

  int get _maxDays =>
      widget.subscriptionViewModel.isPremium ? 7 : 3;

  Future<void> _generate() async {
    if (_weekdays.length > _maxDays) {
      if (!widget.subscriptionViewModel.isPremium) {
        openPremiumPaywall(
          context,
          source: 'meal_plan_days',
          appTelemetry: widget.appTelemetry,
        );
      }
      return;
    }
    if (_mealSlots.isEmpty || _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one meal and one day.')),
      );
      return;
    }

    final budget = double.tryParse(_budgetController.text.trim());
    final diets = [
      ..._dietGoals,
      if (_customDietController.text.trim().isNotEmpty)
        _customDietController.text.trim(),
    ];

    final ok = await widget.mealPlanViewModel.generate(
      GenerateMealPlanRequest(
        dietGoals: diets,
        cuisines: _cuisines.toList(),
        mealSlots: _mealSlots.toList(),
        weekdays: _weekdays.toList()..sort(),
        ingredients: _ingredients,
        weeklyBudgetUsd: budget,
      ),
    );
    if (!mounted) return;
    if (ok) {
      context.pushReplacement('/meal-plan/review');
    } else {
      final err = widget.mealPlanViewModel.error ?? 'Could not generate plan';
      if (err.contains('meal_plan_day_limit') ||
          err.toLowerCase().contains('upgrade')) {
        openPremiumPaywall(
          context,
          source: 'meal_plan_generate',
          appTelemetry: widget.appTelemetry,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.mealPlanViewModel,
        widget.subscriptionViewModel,
      ]),
      builder: (context, _) {
        final loading = widget.mealPlanViewModel.loading;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.mealPlanWizardTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: loading ? null : () => context.pop(),
            ),
          ),
          body: loading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(AppStrings.mealPlanGenerating),
                    ],
                  ),
                )
              : Stepper(
                  currentStep: _step,
                  onStepContinue: () {
                    if (_step < 5) {
                      setState(() => _step += 1);
                    } else {
                      _generate();
                    }
                  },
                  onStepCancel: () {
                    if (_step > 0) {
                      setState(() => _step -= 1);
                    } else {
                      context.pop();
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          FilledButton(
                            onPressed: details.onStepContinue,
                            child: Text(_step == 5 ? 'Generate' : 'Next'),
                          ),
                          const SizedBox(width: 12),
                          if (_step > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text(AppStrings.mealPlanStepDiet),
                      isActive: _step >= 0,
                      content: _chipSection(
                        _dietChips,
                        _dietGoals,
                        (s, sel) => setState(() {
                          if (sel) {
                            _dietGoals.add(s);
                          } else {
                            _dietGoals.remove(s);
                          }
                        }),
                        extra: TextField(
                          controller: _customDietController,
                          decoration: const InputDecoration(
                            hintText: 'Other goals (optional)',
                          ),
                        ),
                      ),
                    ),
                    Step(
                      title: const Text(AppStrings.mealPlanStepCuisines),
                      isActive: _step >= 1,
                      content: _chipSection(
                        _cuisineChips,
                        _cuisines,
                        (s, sel) => setState(() {
                          if (sel) {
                            _cuisines.add(s);
                          } else {
                            _cuisines.remove(s);
                          }
                        }),
                      ),
                    ),
                    Step(
                      title: const Text(AppStrings.mealPlanStepMeals),
                      isActive: _step >= 2,
                      content: Wrap(
                        spacing: 8,
                        children: [
                          _mealChip(AppStrings.mealPlanBreakfast, 'breakfast'),
                          _mealChip(AppStrings.mealPlanLunch, 'lunch'),
                          _mealChip(AppStrings.mealPlanDinner, 'dinner'),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text(AppStrings.mealPlanStepDays),
                      isActive: _step >= 3,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.subscriptionViewModel.isPremium)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                AppStrings.mealPlanFreeDayLimit,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                            ),
                          Wrap(
                            spacing: 8,
                            children: _weekdayMeta.map((e) {
                              final selected = _weekdays.contains(e.$1);
                              return FilterChip(
                                label: Text(e.$2),
                                selected: selected,
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      if (_weekdays.length >= _maxDays) {
                                        if (!widget
                                            .subscriptionViewModel.isPremium) {
                                          openPremiumPaywall(
                                            context,
                                            source: 'meal_plan_day_picker',
                                            appTelemetry: widget.appTelemetry,
                                          );
                                        }
                                        return;
                                      }
                                      _weekdays.add(e.$1);
                                    } else {
                                      _weekdays.remove(e.$1);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text(AppStrings.mealPlanStepPantry),
                      isActive: _step >= 4,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _pantryController,
                            decoration: const InputDecoration(
                              hintText: 'Add ingredient and press +',
                            ),
                            onSubmitted: _addIngredient,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              onPressed: () =>
                                  _addIngredient(_pantryController.text),
                              icon: const Icon(Icons.add),
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ..._ingredients.map(
                                (i) => InputChip(
                                  label: Text(i),
                                  onDeleted: () =>
                                      setState(() => _ingredients.remove(i)),
                                ),
                              ),
                              ...PantryItems.suggestedForCuisines(
                                    _cuisines.toList(),
                                  )
                                  .take(12)
                                  .map(
                                    (s) => ActionChip(
                                      label: Text(s),
                                      onPressed: () {
                                        if (!_ingredients.contains(s)) {
                                          setState(() => _ingredients.add(s));
                                        }
                                      },
                                    ),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text(AppStrings.mealPlanStepBudget),
                      isActive: _step >= 5,
                      content: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: '\$ ',
                          hintText: '85',
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _addIngredient(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return;
    setState(() {
      if (!_ingredients.contains(t)) _ingredients.add(t);
      _pantryController.clear();
    });
    widget.sessionManager.saveIngredientsSync(_ingredients);
  }

  Widget _mealChip(String label, String value) {
    final selected = _mealSlots.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _mealSlots.add(value);
          } else if (_mealSlots.length > 1) {
            _mealSlots.remove(value);
          }
        });
      },
    );
  }

  Widget _chipSection(
    List<String> options,
    Set<String> selected,
    void Function(String, bool) onChanged, {
    Widget? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options
              .map(
                (s) => FilterChip(
                  label: Text(s),
                  selected: selected.contains(s),
                  onSelected: (v) => onChanged(s, v),
                ),
              )
              .toList(),
        ),
        if (extra != null) ...[const SizedBox(height: 12), extra],
      ],
    );
  }
}
