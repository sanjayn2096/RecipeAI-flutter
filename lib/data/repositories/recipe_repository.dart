import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
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

  /// Uses feature-flagged flow:
  /// - control: POST /generate-recipe
  /// - stream/experiment: POST /generate-recipes-stream
  Future<List<Recipe>> fetchRecipesFromBackend({
    void Function(Recipe recipe)? onRecipe,
    void Function(bool isStreaming)? onFlowSelected,
  }) async {
    if (_api == null) {
      if (kDebugMode) debugPrint('[RecipeRepository] fetchRecipesFromBackend: no ApiService, returning empty');
      return [];
    }

    final user = _firebaseAuth.currentUser;
    final idToken = await user?.getIdToken();
    final String? anonymousId =
        user == null ? await _session.getOrCreateAnonymousId() : null;
    final actorId = user?.uid ?? anonymousId ?? 'unknown';
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

    final req = GenerateRecipeRequest(
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
    );

    final useStreaming = FeatureFlags.useStreamingRecipeGeneration(actorId);
    onFlowSelected?.call(useStreaming);

    if (kDebugMode) {
      debugPrint(
        '[RecipeRepository] fetchRecipesFromBackend() -> '
        '${useStreaming ? 'POST generate-recipes-stream' : 'POST generate-recipe'}',
      );
    }

    if (useStreaming) {
      final streamed = <Recipe>[];
      await for (final recipe in _api!.generateRecipeStream(req, idToken: idToken)) {
        streamed.add(recipe);
        onRecipe?.call(recipe);
      }
      if (user == null) {
        await _session.recordGuestRecipeGenerationSuccess();
      }
      return streamed;
    }

    final res = await _api!.generateRecipe(req, idToken: idToken);
    if (user == null) {
      await _session.recordGuestRecipeGenerationSuccess();
    }
    return res.recipes;
  }

  /// Same as [fetchRecipesFromBackend] — all recipe lists come from the backend.
  Future<List<Recipe>> fetchRecipes({
    void Function(Recipe recipe)? onRecipe,
    void Function(bool isStreaming)? onFlowSelected,
  }) =>
      fetchRecipesFromBackend(
        onRecipe: onRecipe,
        onFlowSelected: onFlowSelected,
      );
}
