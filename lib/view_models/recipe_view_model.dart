import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/recipe_parsing.dart';
import '../core/recipe_fetch_error_message.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/api_dtos.dart';
import '../data/models/recipe.dart';
import '../core/feature_flags.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/recipe_image_cache.dart';

bool _kRecipeLogging = kDebugMode;

class RecipeViewModel extends ChangeNotifier {
  RecipeViewModel({
    required RecipeRepository recipeRepository,
    required UserRepository userRepository,
    required AppTelemetry appTelemetry,
    required RecipeImageCache recipeImageCache,
  })  : _recipeRepo = recipeRepository,
        _userRepo = userRepository,
        _telemetry = appTelemetry,
        _imageCache = recipeImageCache;

  final RecipeRepository _recipeRepo;
  final UserRepository _userRepo;
  final AppTelemetry _telemetry;
  final RecipeImageCache _imageCache;

  List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isStreamingFlow = false;
  bool get isStreamingFlow => _isStreamingFlow;

  String? _fetchError;
  String? get fetchError => _fetchError;

  bool _isBeingEdited = false;
  bool get isBeingEdited => _isBeingEdited;

  RecipeImageCache get recipeImageCache => _imageCache;

  /// POST generate-recipe with structured session fields (server builds prompt).
  Future<void> fetchRecipes() async {
    if (_kRecipeLogging) debugPrint('[RecipeViewModel] fetchRecipes() -> backend recipe generation flow');
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.generateRecipe,
      action: 'submit',
    );
    _isLoading = true;
    _isStreamingFlow = false;
    _fetchError = null;
    _recipes = [];
    notifyListeners();
    try {
      final streamedRecipes = <Recipe>[];
      _recipes = await _recipeRepo.fetchRecipes(
        onFlowSelected: (isStreaming) {
          _isStreamingFlow = isStreaming;
          notifyListeners();
        },
        onRecipe: (recipe) {
          streamedRecipes.add(recipe);
          _recipes = List<Recipe>.from(streamedRecipes);
          notifyListeners();
        },
      );
      _fetchError = null;
    } catch (e, st) {
      _recipes = [];
      _fetchError = recipeFetchErrorMessage(e);
      if (_kRecipeLogging) {
        debugPrint('[RecipeViewModel] fetchRecipes failed: $e');
        debugPrint('$st');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRecipesFromPrompt() => fetchRecipes();

  void scheduleLifestyleSync() {
    unawaited(_userRepo.syncLifestyleFromPrefs());
  }

  void clearRecipeGenerationState() {
    _fetchError = null;
    _recipes = [];
    notifyListeners();
  }

  void setBeingEdited() {
    _isBeingEdited = true;
    notifyListeners();
  }

  String _cuisineParam(Recipe recipe) {
    final c = recipe.cuisine.trim();
    if (c.isEmpty || c == 'No Cuisine Selected') return '';
    return c;
  }

  String? _cuisineOrNull(Recipe recipe) {
    final s = _cuisineParam(recipe);
    return s.isEmpty ? null : s;
  }

  /// Resolves instruction lines for image APIs (match cook / show).
  List<String> _instructionLines(Recipe recipe) {
    var steps = RecipeParsing.parseInstructions(recipe.instructions);
    if (steps.isEmpty) {
      final raw = recipe.instructions.trim();
      if (raw.isNotEmpty) {
        steps = [raw];
      }
    }
    return steps;
  }

  String _clientRequestId(Recipe recipe) => recipe.recipeId.trim().isNotEmpty
      ? recipe.recipeId
      : 'recipe-${recipe.recipeName.hashCode}';

  /// Hero + first step (index 0) on recipe open. Uses local cache; parallel API on miss.
  /// Respects [FeatureFlags.recipeImagesAutoGenerateOnOpen]. Returns [recipe] with merged URLs.
  Future<Recipe> ensureHeroAndFirstStepImages(Recipe recipe) async {
    if (!FeatureFlags.recipeImagesAutoGenerateOnOpen) {
      return recipeWithCachedImages(recipe);
    }
    final lines = _instructionLines(recipe);
    if (lines.isEmpty) {
      return recipeWithCachedImages(recipe);
    }
    final stepCount = lines.length;
    final ins = recipe.instructions;
    final id = recipe.recipeId;

    final cached = await _imageCache.get(id, ins);
    if (cached != null) {
      final h = _httpUrl(cached.heroUrl) ? cached.heroUrl : '';
      var s0 = '';
      if (cached.stepUrls.isNotEmpty) {
        s0 = _httpUrl(cached.stepUrls[0]) ? cached.stepUrls[0] : '';
      }
      if (h.isNotEmpty && s0.isNotEmpty) {
        final stepUrls = List<String>.filled(stepCount, '');
        for (var i = 0; i < stepCount && i < cached.stepUrls.length; i++) {
          stepUrls[i] = cached.stepUrls[i];
        }
        final merged = recipe.copyWith(image: h, stepImageUrls: stepUrls);
        replaceRecipeInGeneratedList(merged);
        return merged;
      }
    }

    try {
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.generateRecipeImages,
        action: 'submit',
      );
    } catch (_) {}

    final cuisine = _cuisineOrNull(recipe);
    final crid = _clientRequestId(recipe);
    final heroReq = GenerateRecipeHeroRequest(
      recipeName: recipe.recipeName,
      cuisine: cuisine,
      clientRequestId: crid,
    );
    final step0Req = GenerateRecipeStepImageRequest(
      recipeName: recipe.recipeName,
      stepText: lines[0],
      stepIndex: 0,
      cuisine: cuisine,
      clientRequestId: crid,
    );

    final heroFuture = _recipeRepo.generateRecipeHero(heroReq);
    final step0Future = _recipeRepo.generateRecipeStepImage(step0Req);
    final results = await Future.wait([heroFuture, step0Future]);
    final heroRes = results[0] as GenerateRecipeHeroResponse;
    final step0Res = results[1] as GenerateRecipeStepImageResponse;

    final heroUrl = heroRes.recipeImageUrl;
    final step0Url = step0Res.imageUrl;

    await _imageCache.setHero(id, ins, heroUrl, stepCount: stepCount);
    await _imageCache.setStepUrl(id, ins, 0, step0Url, stepCount: stepCount);

    final stepUrls = List<String>.filled(stepCount, '');
    stepUrls[0] = step0Url;
    final updated = recipe.copyWith(
      image: heroUrl,
      stepImageUrls: stepUrls,
    );
    replaceRecipeInGeneratedList(updated);
    unawaited(persistGeneratedRecipeImages(updated));
    return updated;
  }

  static bool _httpUrl(String s) {
    final t = s.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  /// GET /get-recipe/:id — optional; returns null on 404.
  Future<Recipe?> tryFetchRecipeFromFirestore(String recipeId) async {
    final r = recipeId.trim();
    if (r.isEmpty) return null;
    try {
      return await _userRepo.fetchRecipeById(r);
    } catch (_) {
      return null;
    }
  }

  Future<void> persistGeneratedRecipeImages(Recipe recipe) async {
    await _userRepo.mergeRecipeDocument(recipe);
  }

  void replaceRecipeInGeneratedList(Recipe updated) {
    final id = updated.recipeId;
    _recipes = _recipes.map((r) => r.recipeId == id ? updated : r).toList();
    notifyListeners();
  }

  /// One step image; updates cache. Used from cook flow after "Let's get cooking."
  Future<String> ensureStepImageUrl({
    required Recipe recipe,
    required int stepIndex,
  }) async {
    final lines = _instructionLines(recipe);
    if (stepIndex < 0 || stepIndex >= lines.length) {
      throw StateError('Invalid step index');
    }
    final ins = recipe.instructions;
    final id = recipe.recipeId;
    final stepCount = lines.length;
    final cached = await _imageCache.get(id, ins);
    if (cached != null &&
        cached.stepUrls.length > stepIndex &&
        _httpUrl(cached.stepUrls[stepIndex])) {
      return cached.stepUrls[stepIndex].trim();
    }
    try {
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.generateRecipeImages,
        action: 'submit',
      );
    } catch (_) {}
    final res = await _recipeRepo.generateRecipeStepImage(
      GenerateRecipeStepImageRequest(
        recipeName: recipe.recipeName,
        stepText: lines[stepIndex],
        stepIndex: stepIndex,
        cuisine: _cuisineOrNull(recipe),
        clientRequestId: _clientRequestId(recipe),
      ),
    );
    final url = res.imageUrl.trim();
    await _imageCache.setStepUrl(id, ins, stepIndex, url, stepCount: stepCount);
    return url;
  }

  /// Fire-and-forget next step; ignores errors.
  void prefetchNextStepIfNeeded(Recipe recipe, int currentIndex) {
    final lines = _instructionLines(recipe);
    final next = currentIndex + 1;
    if (next >= lines.length) return;
    unawaited(() async {
      try {
        await ensureStepImageUrl(recipe: recipe, stepIndex: next);
      } catch (_) {}
    }());
  }

  /// Merge cached URLs into [recipe] for display / navigation.
  Future<Recipe> recipeWithCachedImages(Recipe recipe) async {
    final cached = await _imageCache.get(recipe.recipeId, recipe.instructions);
    if (cached == null) return recipe;
    final lines = _instructionLines(recipe);
    final n = lines.length;
    if (n == 0) {
      if (_httpUrl(cached.heroUrl)) {
        return recipe.copyWith(image: cached.heroUrl);
      }
      return recipe;
    }
    var urls = List<String>.filled(n, '');
    for (var i = 0; i < n && i < cached.stepUrls.length; i++) {
      urls[i] = cached.stepUrls[i];
    }
    var img = recipe.image;
    if (_httpUrl(cached.heroUrl)) {
      img = cached.heroUrl;
    }
    return recipe.copyWith(image: img, stepImageUrls: urls);
  }

  /// Toggles favorite on the backend and updates [recipes].
  Future<bool> toggleFavorite(Recipe recipe) async {
    final updated = recipe.copyWith(isFavorite: !recipe.isFavorite);
    try {
      await _telemetry.logFeatureInteraction(featureId: FeatureIds.toggleFavorite);
      await _userRepo.saveFavoriteRecipe(updated);
      _recipes = _recipes
          .map((r) => r.recipeId == updated.recipeId ? updated : r)
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
