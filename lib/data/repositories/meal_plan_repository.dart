import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_service.dart';
import '../local/meal_plan_hive_store.dart';
import '../models/meal_plan.dart';
import '../../services/session_manager.dart';

class MealPlanRepository {
  MealPlanRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
    required MealPlanHiveStore hiveStore,
    FirebaseAuth? firebaseAuth,
  })  : _api = apiService,
        _session = sessionManager,
        _hive = hiveStore,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final ApiService _api;
  final SessionManager _session;
  final MealPlanHiveStore _hive;
  final FirebaseAuth _auth;

  MealPlanResult? readCachedPlan() => _hive.readLatestSync();

  Future<void> cachePlan(MealPlanResult plan) => _hive.writeLatest(plan);

  Future<MealPlanResult> generatePlan(GenerateMealPlanRequest request) async {
    final user = _auth.currentUser;
    final idToken = await user?.getIdToken();
    final anonymousId =
        user == null ? await _session.getOrCreateAnonymousId() : null;
    final body = GenerateMealPlanRequest(
      dietGoals: request.dietGoals,
      cuisines: request.cuisines,
      mealSlots: request.mealSlots,
      weekdays: request.weekdays,
      ingredients: request.ingredients,
      weeklyBudgetUsd: request.weeklyBudgetUsd,
      postalCode: request.postalCode,
      anonymousId: anonymousId,
      excludeRecipeNames: request.excludeRecipeNames,
    );
    final result = await _api.generateMealPlan(body, idToken: idToken);
    await _hive.writeLatest(result);
    return result;
  }

  Future<MealPlanResult> regenerateSlot(
    RegenerateMealPlanSlotRequest request,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException(403, 'Sign in to regenerate meals.');
    }
    final idToken = await user.getIdToken();
    final result =
        await _api.regenerateMealPlanSlot(request, idToken: idToken);
    await _hive.writeLatest(result);
    return result;
  }
}
