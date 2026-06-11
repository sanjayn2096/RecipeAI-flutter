import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../models/meal_plan.dart';

/// Guest / offline cache for the latest generated meal plan.
class MealPlanHiveStore {
  MealPlanHiveStore(this._box);

  final Box<String> _box;

  static const _latestKey = 'latest_plan_json';

  MealPlanResult? readLatestSync() {
    final raw = _box.get(_latestKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return MealPlanResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeLatest(MealPlanResult plan) async {
    await _box.put(_latestKey, jsonEncode(_planToJson(plan)));
  }

  Future<void> clear() async {
    await _box.delete(_latestKey);
  }

  static Map<String, dynamic> _planToJson(MealPlanResult plan) {
    return {
      'assistantMessage': plan.assistantMessage,
      'planId': plan.planId,
      'days': plan.days
          .map(
            (d) => {
              'date': d.date,
              'slots': d.slots
                  .map(
                    (s) => {
                      'meal': s.meal,
                      'recipe': s.recipe.toJsonForSaveFavorite(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'missingIngredients': plan.missingIngredients
          .map(
            (m) => {
              'name': m.name,
              'quantity': m.quantity,
              'unit': m.unit,
              'estimatedUsd': m.estimatedUsd,
              'usedByRecipes': m.usedByRecipes,
            },
          )
          .toList(),
      'costSummary': {
        'estimatedTotalUsd': plan.costSummary.estimatedTotalUsd,
        'budgetUsd': plan.costSummary.budgetUsd,
        'withinBudget': plan.costSummary.withinBudget,
      },
      'instacart': {
        'status': plan.instacart.status,
        'listUrl': plan.instacart.listUrl,
      },
    };
  }

  static Future<Box<String>> openBox() async {
    return Hive.openBox<String>(AppConstants.hiveMealPlanBox);
  }
}
