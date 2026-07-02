import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants.dart';
import '../../core/feature_flags.dart';
import '../../core/preference_options.dart';
import '../../core/recipe_generation_entry_point.dart';
import '../api/api_service.dart' show ApiService;
import '../../core/recipe_origin.dart';
import '../models/api_dtos.dart';
import '../models/recipe.dart';
import '../../onboarding/onboarding_session_extension.dart';
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

  static const String _importSignInRequired =
      'Sign in to import recipes from links, text, or photos.';

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
    final moodKey = fromHome
        ? _session.getLifestyleMood()
        : _session.getCreateFlowMood();
    final dietKey = fromHome
        ? _session.getLifestyleDietRestrictions()
        : _session.getCreateFlowDietRestrictions();
    final cuisineKey = fromHome
        ? _resolvedCuisineForHomeGeneration()
        : _session.getCreateFlowCuisine();
    final cookingKey = fromHome
        ? _session.getLifestyleCookingPreference()
        : _session.getCreateFlowCookingPreference();

    final RecipeGenerationMode recipeMode;
    if (customPreference.trim().isNotEmpty) {
      recipeMode = RecipeGenerationMode.custom;
    } else if (PreferenceOptions.isFeelingLucky(moodKey)) {
      recipeMode = RecipeGenerationMode.lucky;
    } else {
      recipeMode = RecipeGenerationMode.preferences;
    }

    var dietProfiles = List<String>.from(_session.getDietProfiles());
    if (dietProfiles.isEmpty) {
      if (!PreferenceOptions.isNoRestrictionsDiet(dietKey)) {
        dietProfiles = [dietKey];
      }
    }

    final refinement = userRefinementNote?.trim();
    final req = GenerateRecipeRequest(
      ingredients: List<String>.from(_session.getIngredients()),
      customPreference: customPreference,
      mood: PreferenceOptions.moodToApiEnglish(moodKey),
      dietRestrictions: PreferenceOptions.dietToApiEnglish(dietKey),
      cuisine: fromHome
          ? PreferenceOptions.cuisinesToApiEnglishJoined(
              cuisineKey.contains(',')
                  ? cuisineKey.split(',').map((s) => s.trim()).toList()
                  : [cuisineKey],
            )
          : PreferenceOptions.cuisineToApiEnglish(cuisineKey),
      cookingPreference: PreferenceOptions.cookingToApiEnglish(cookingKey),
      recipeMode: recipeMode,
      dietProfiles: dietProfiles
          .map(PreferenceOptions.dietToApiEnglish)
          .toList(),
      allergensAvoid: _session
          .getAllergensAvoid()
          .map(PreferenceOptions.allergenToApiEnglish)
          .toList(),
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
      } else if (!_session.isGuestMode()) {
        await _session.recordSignedInFreeRecipeGenerationSuccess(
          isPremium: _session.readSubscriptionCacheSync().isPremium,
        );
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
    } else if (!_session.isGuestMode()) {
      await _session.recordSignedInFreeRecipeGenerationSuccess(
        isPremium: _session.readSubscriptionCacheSync().isPremium,
      );
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
        .where(
          (e) =>
              e.isNotEmpty &&
              !PreferenceOptions.isSurpriseCuisine(e),
        )
        .toList();
    if (usual.isNotEmpty) {
      return usual.join(',');
    }
    final single = _session.getLifestyleCuisine().trim();
    if (single.isNotEmpty && !PreferenceOptions.isNoCuisineSelected(single) &&
        !PreferenceOptions.isSurpriseCuisine(single)) {
      return single;
    }
    return PreferenceOptions.noCuisineSelected;
  }

  /// POST /import-recipe — extract one structured recipe server-side (auth).
  Future<Recipe> importRecipe({
    required String mode,
    String? url,
    String? plainText,
  }) async {
    final api = _api;
    if (api == null) throw StateError(_importSignInRequired);
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError(_importSignInRequired);
    final token = await user.getIdToken();
    var raw = await api.importRecipe(
      mode: mode,
      url: url,
      plainText: plainText,
      idToken: token,
    );
    raw = await _resolveHeroImage(raw, idToken: token);
    if (!_session.isGuestMode()) {
      await _session.recordSignedInFreeImportSuccess(
        isPremium: _session.readSubscriptionCacheSync().isPremium,
      );
    }
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
