import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../api/api_service.dart';
import '../models/api_dtos.dart';
import '../models/recipe.dart';
import '../../services/session_manager.dart';
import '../../core/prompt_builder.dart';

/// Fetches recipes via backend `generate-recipe` only (no client-side LLM).
class RecipeRepository {
  RecipeRepository({
    required SessionManager sessionManager,
    ApiService? apiService,
    FirebaseAuth? firebaseAuth,
    PromptBuilder? promptBuilder,
  })  : _session = sessionManager,
        _api = apiService,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _promptBuilder =
            promptBuilder ?? PromptBuilder(sessionManager: sessionManager);

  final SessionManager _session;
  final ApiService? _api;
  final FirebaseAuth _firebaseAuth;
  final PromptBuilder _promptBuilder;

  /// POST generate-recipe. [PromptBuilder] uses session (customPreference or mood/diet/cuisine/cooking).
  Future<List<Recipe>> fetchRecipesFromBackend() async {
    if (_api == null) {
      if (kDebugMode) debugPrint('[RecipeRepository] fetchRecipesFromBackend: no ApiService, returning empty');
      return [];
    }
    final prompt = _promptBuilder.build();
    if (kDebugMode) {
      debugPrint('[RecipeRepository] fetchRecipesFromBackend() -> POST generate-recipe');
    }
    final user = _firebaseAuth.currentUser;
    final idToken = await user?.getIdToken();
    final String? anonymousId =
        user == null ? await _session.getOrCreateAnonymousId() : null;
    final res = await _api!.generateRecipe(
      GenerateRecipeRequest(prompt: prompt, anonymousId: anonymousId),
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
