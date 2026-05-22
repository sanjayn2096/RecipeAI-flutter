import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_strings.dart';
import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../core/recipe_generation_entry_point.dart';
import '../api/api_service.dart' show ApiService;
import '../../core/recipe_origin.dart';
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
  Future<RecipeBatchResult> fetchRecipesFromBackend({
    void Function(Recipe recipe)? onRecipe,
    void Function(bool isStreaming)? onFlowSelected,
    void Function(String assistantMessage)? onAssistantMessage,
    List<String> excludeRecipeNames = const [],
    String? userRefinementNote,
    int generationAttempt = 1,
    RecipeGenerationEntryPoint generationSource =
        RecipeGenerationEntryPoint.createRecipes,
  }) async {
    if (_api == null) {
      if (kDebugMode) debugPrint('[RecipeRepository] fetchRecipesFromBackend: no ApiService, returning empty');
      return const RecipeBatchResult(recipes: []);
    }

    final user = _firebaseAuth.currentUser;
    final idToken = await user?.getIdToken();
    final String? anonymousId =
        user == null ? await _session.getOrCreateAnonymousId() : null;
    final actorId = user?.uid ?? anonymousId ?? 'unknown';
    final customPreference =
        _session.getPreference(AppConstants.prefsCustomPreference) ?? '';

    final bool fromHome = generationSource == RecipeGenerationEntryPoint.home;
    final mood = fromHome
        ? _session.getLifestyleMood()
        : _session.getCreateFlowMood();
    final dietLine = fromHome
        ? _session.getLifestyleDietRestrictions()
        : _session.getCreateFlowDietRestrictions();
    final cuisine = fromHome
        ? _resolvedCuisineForHomeGeneration()
        : _session.getCreateFlowCuisine();
    final cooking = fromHome
        ? _session.getLifestyleCookingPreference()
        : _session.getCreateFlowCookingPreference();

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
      final dr = dietLine;
      if (dr.isNotEmpty &&
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
      dietRestrictions: dietLine,
      cuisine: cuisine,
      cookingPreference: cooking,
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
      String? assistantMessage;
      await for (final recipe in _api!.generateRecipeStream(
        req,
        idToken: idToken,
        onAssistantMessage: (msg) {
          assistantMessage = msg;
          onAssistantMessage?.call(msg);
        },
      )) {
        final enriched = await _resolveHeroImage(recipe, idToken: idToken);
        streamed.add(enriched);
        onRecipe?.call(enriched);
      }
      if (user == null) {
        await _session.recordGuestRecipeGenerationSuccess();
      }
      return RecipeBatchResult(
        recipes: streamed,
        assistantMessage: assistantMessage,
      );
    }

    final res = await _api!.generateRecipe(req, idToken: idToken);
    final enriched = await Future.wait(
      res.recipes.map((r) => _resolveHeroImage(r, idToken: idToken)),
    );
    if (user == null) {
      await _session.recordGuestRecipeGenerationSuccess();
    }
    return RecipeBatchResult(
      recipes: enriched,
      assistantMessage: res.assistantMessage,
    );
  }

  /// Same as [fetchRecipesFromBackend] — all recipe lists come from the backend.
  Future<RecipeBatchResult> fetchRecipes({
    void Function(Recipe recipe)? onRecipe,
    void Function(bool isStreaming)? onFlowSelected,
    void Function(String assistantMessage)? onAssistantMessage,
    List<String> excludeRecipeNames = const [],
    String? userRefinementNote,
    int generationAttempt = 1,
    RecipeGenerationEntryPoint generationSource =
        RecipeGenerationEntryPoint.createRecipes,
  }) =>
      fetchRecipesFromBackend(
        onRecipe: onRecipe,
        onFlowSelected: onFlowSelected,
        onAssistantMessage: onAssistantMessage,
        excludeRecipeNames: excludeRecipeNames,
        userRefinementNote: userRefinementNote,
        generationAttempt: generationAttempt,
        generationSource: generationSource,
      );

  /// Stable preferred cuisines (`usualCuisines`) beat legacy single-field lifestyle cuisine.
  String _resolvedCuisineForHomeGeneration() {
    final usual = _session
        .getUsualCuisines()
        .map((e) => e.trim())
        .where(
          (e) =>
              e.isNotEmpty &&
              e != AppStrings.surpriseMe,
        )
        .toList();
    if (usual.isNotEmpty) {
      return usual.join(', ');
    }
    final single = (_session.getLifestyleCuisine()).trim();
    if (single.isNotEmpty &&
        single != 'No Cuisine Selected' &&
        single != AppStrings.surpriseMe) {
      return single;
    }
    return 'No Cuisine Selected';
  }

  /// POST /import-recipe — extract one structured recipe server-side (auth).
  Future<Recipe> importRecipe({
    required String mode,
    String? url,
    String? plainText,
  }) async {
    final api = _api;
    if (api == null) throw StateError(AppStrings.importRecipeSignInRequired);
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError(AppStrings.importRecipeSignInRequired);
    final token = await user.getIdToken();
    var raw = await api.importRecipe(
      mode: mode,
      url: url,
      plainText: plainText,
      idToken: token,
    );
    raw = await _resolveHeroImage(raw, idToken: token);
    return raw.copyWith(recipeOrigin: RecipeOrigin.imported);
  }

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
