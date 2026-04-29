import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../api/api_service.dart' show ApiService;
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
    List<String> excludeRecipeNames = const [],
    String? userRefinementNote,
    int generationAttempt = 1,
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

    var dietProfiles = List<String>.from(_session.getDietProfiles());
    if (dietProfiles.isEmpty) {
      final dr = _session.getDietRestrictions();
      if (dr != null &&
          dr.isNotEmpty &&
          dr != 'No Diet Restrictions' &&
          dr != AppStrings.noRestrictions) {
        dietProfiles = [dr];
      }
    }

    final refinement = userRefinementNote?.trim();
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
      dietProfiles: dietProfiles,
      allergensAvoid: List<String>.from(_session.getAllergensAvoid()),
      allergyNotes: _session.getAllergyNotes(),
      anonymousId: anonymousId,
      excludeRecipeNames: List<String>.from(excludeRecipeNames),
      userRefinementNote:
          refinement != null && refinement.isNotEmpty ? refinement : null,
      generationAttempt: generationAttempt < 2 ? null : generationAttempt,
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
        final enriched = await _resolveHeroImage(recipe, idToken: idToken);
        streamed.add(enriched);
        onRecipe?.call(enriched);
      }
      if (user == null) {
        await _session.recordGuestRecipeGenerationSuccess();
      }
      return streamed;
    }

    final res = await _api!.generateRecipe(req, idToken: idToken);
    final enriched = await Future.wait(
      res.recipes.map((r) => _resolveHeroImage(r, idToken: idToken)),
    );
    if (user == null) {
      await _session.recordGuestRecipeGenerationSuccess();
    }
    return enriched;
  }

  /// Same as [fetchRecipesFromBackend] — all recipe lists come from the backend.
  Future<List<Recipe>> fetchRecipes({
    void Function(Recipe recipe)? onRecipe,
    void Function(bool isStreaming)? onFlowSelected,
    List<String> excludeRecipeNames = const [],
    String? userRefinementNote,
    int generationAttempt = 1,
  }) =>
      fetchRecipesFromBackend(
        onRecipe: onRecipe,
        onFlowSelected: onFlowSelected,
        excludeRecipeNames: excludeRecipeNames,
        userRefinementNote: userRefinementNote,
        generationAttempt: generationAttempt,
      );

  Future<Recipe> _resolveHeroImage(Recipe recipe, {String? idToken}) async {
    final existing = recipe.image.trim();
    if (existing.startsWith('http://') || existing.startsWith('https://')) {
      return recipe;
    }
    if (_api == null) return recipe;
    try {
      final resp = await _api!.resolveRecipeHero(
        recipeName: recipe.recipeName,
        cuisine: recipe.cuisine,
        idToken: idToken,
      );
      return recipe.copyWith(image: resp.recipeImageUrl.trim());
    } catch (_) {
      return recipe;
    }
  }
}
