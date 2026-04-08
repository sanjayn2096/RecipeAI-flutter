import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../api/api_service.dart';
import '../models/api_dtos.dart';
import '../models/recipe.dart';
import '../../services/session_manager.dart';

/// Fetches recipes via backend `generate-recipe` only (no client-side LLM).
class RecipeRepository {
  RecipeRepository({
    required SessionManager sessionManager,
    ApiService? apiService,
    FirebaseAuth? firebaseAuth,
  })  : _session = sessionManager,
        _api = apiService,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final SessionManager _session;
  final ApiService? _api;
  final FirebaseAuth _firebaseAuth;

  /// POST generate-recipe with structured preferences (server builds the LLM prompt).
  Future<List<Recipe>> fetchRecipesFromBackend() async {
    if (_api == null) {
      if (kDebugMode) debugPrint('[RecipeRepository] fetchRecipesFromBackend: no ApiService, returning empty');
      return [];
    }
    if (kDebugMode) {
      debugPrint('[RecipeRepository] fetchRecipesFromBackend() -> POST generate-recipe');
    }
    final user = _firebaseAuth.currentUser;
    final idToken = await user?.getIdToken();
    final String? anonymousId =
        user == null ? await _session.getOrCreateAnonymousId() : null;
    final customPreference =
        _session.getPreference(AppConstants.prefsCustomPreference) ?? '';
    final mood = _session.getMood() ?? 'lucky';
    final RecipeGenerationMode recipeMode;
    if (customPreference.trim().isNotEmpty) {
      recipeMode = RecipeGenerationMode.custom;
    } else if (mood == AppStrings.feelingLucky) {
      recipeMode = RecipeGenerationMode.lucky;
    } else {
      recipeMode = RecipeGenerationMode.preferences;
    }
    final res = await _api!.generateRecipe(
      GenerateRecipeRequest(
        ingredients: List<String>.from(_session.getIngredients()),
        customPreference: customPreference,
        mood: mood,
        dietRestrictions:
            _session.getDietRestrictions() ?? 'No Diet Restrictions',
        cuisine: _session.getCuisine() ?? 'No Cuisine Selected',
        cookingPreference:
            _session.getCookingPreference() ?? 'No Cooking Preferences',
        recipeMode: recipeMode,
        anonymousId: anonymousId,
      ),
      idToken: idToken,
    );
    if (user == null) {
      await _session.recordGuestRecipeGenerationSuccess();
    }
    return res.recipes;
  }

  /// Same as [fetchRecipesFromBackend] — all recipe lists come from the backend.
  Future<List<Recipe>> fetchRecipes() => fetchRecipesFromBackend();
}
