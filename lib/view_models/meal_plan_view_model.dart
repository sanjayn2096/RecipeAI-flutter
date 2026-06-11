import 'package:flutter/foundation.dart';

import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/api/api_service.dart';
import '../data/models/meal_plan.dart';
import '../data/repositories/meal_plan_repository.dart';

class MealPlanViewModel extends ChangeNotifier {
  MealPlanViewModel({
    required MealPlanRepository repository,
    required AppTelemetry appTelemetry,
  })  : _repo = repository,
        _telemetry = appTelemetry;

  final MealPlanRepository _repo;
  final AppTelemetry _telemetry;

  MealPlanResult? _plan;
  MealPlanResult? get plan => _plan;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<MissingIngredientLine> _missing = [];
  List<MissingIngredientLine> get missingIngredients =>
      List.unmodifiable(_missing);

  void loadCached() {
    _plan = _repo.readCachedPlan();
    _missing = _plan?.missingIngredients
            .map((m) => m.copyWith(selected: true))
            .toList() ??
        [];
    _error = null;
    notifyListeners();
  }

  void toggleMissingSelected(int index, bool value) {
    if (index < 0 || index >= _missing.length) return;
    _missing = List<MissingIngredientLine>.from(_missing);
    _missing[index] = _missing[index].copyWith(selected: value);
    notifyListeners();
  }

  Future<bool> generate(GenerateMealPlanRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.generatePlan(request);
      _plan = result;
      _missing = result.missingIngredients
          .map((m) => m.copyWith(selected: true))
          .toList();
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.mealPlanGenerate,
      );
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> regenerateSlot({
    required String date,
    required String meal,
    List<String> ingredients = const [],
  }) async {
    final p = _plan;
    if (p == null || p.planId.isEmpty) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final exclude = p.days
          .expand((d) => d.slots)
          .map((s) => s.recipe.recipeName)
          .where((n) => n.isNotEmpty)
          .toList();
      final result = await _repo.regenerateSlot(
        RegenerateMealPlanSlotRequest(
          planId: p.planId,
          date: date,
          meal: meal,
          ingredients: ingredients,
          excludeRecipeNames: exclude,
        ),
      );
      _plan = MealPlanResult(
        assistantMessage: result.assistantMessage ?? p.assistantMessage,
        planId: result.planId.isNotEmpty ? result.planId : p.planId,
        days: result.days.isNotEmpty ? result.days : p.days,
        missingIngredients: result.missingIngredients,
        costSummary: result.costSummary,
        instacart: result.instacart,
      );
      _missing = _plan!.missingIngredients
          .map((m) => m.copyWith(selected: true))
          .toList();
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.mealPlanRegenerateSlot,
      );
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<String> selectedMissingGroceryLines() {
    return _missing
        .where((m) => m.selected && m.name.trim().isNotEmpty)
        .map((m) => m.toGroceryLine())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
