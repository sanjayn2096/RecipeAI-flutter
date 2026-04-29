import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/recipe_fetch_error_message.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/recipe.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';

bool _kRecipeLogging = kDebugMode;

List<Recipe> _dedupeRecipesByNormalizedTitle(List<Recipe> items) {
  final seen = <String>{};
  final out = <Recipe>[];
  for (final r in items) {
    final k = r.recipeName.trim().toLowerCase();
    if (k.isEmpty) {
      out.add(r);
      continue;
    }
    if (seen.contains(k)) continue;
    seen.add(k);
    out.add(r);
  }
  return out;
}

class RecipeViewModel extends ChangeNotifier {
  RecipeViewModel({
    required RecipeRepository recipeRepository,
    required UserRepository userRepository,
    required AppTelemetry appTelemetry,
  })  : _recipeRepo = recipeRepository,
        _userRepo = userRepository,
        _telemetry = appTelemetry;

  final RecipeRepository _recipeRepo;
  final UserRepository _userRepo;
  final AppTelemetry _telemetry;

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

  /// Counts finished generation batches so follow-ups ([fetchMoreRecipes]) get `generationAttempt >= 2`.
  int _successfulGenerationAttempts = 0;

  /// POST generate-recipe with structured session fields (server builds prompt).
  Future<void> fetchRecipes() async {
    if (_kRecipeLogging) {
      debugPrint('[RecipeViewModel] fetchRecipes() -> backend recipe generation flow');
    }
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.generateRecipe,
      action: 'submit',
    );
    _successfulGenerationAttempts = 0;
    _isLoading = true;
    _isStreamingFlow = false;
    _fetchError = null;
    _recipes = [];
    notifyListeners();
    try {
      final streamedRecipes = <Recipe>[];
      _recipes = await _recipeRepo.fetchRecipes(
        generationAttempt: 1,
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
      _successfulGenerationAttempts = 1;
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

  /// Loads another batch against the same session preferences — replaces or appends depending on [append].
  /// Keeps showing the previous list until the new response replaces it (streaming) or swaps in one shot (batch).
  Future<void> fetchMoreRecipes({
    bool append = false,
    String? refinementNote,
  }) async {
    if (_recipes.isEmpty) return;
    if (_kRecipeLogging) {
      debugPrint(
        '[RecipeViewModel] fetchMoreRecipes append=$append refinement=${refinementNote ?? ""}',
      );
    }
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.generateRecipeFollowUp,
      action: append ? 'append_batch' : 'replace_batch',
    );

    final prior = List<Recipe>.from(_recipes);
    final excludeNames =
        prior.map((r) => r.recipeName.trim()).where((s) => s.isNotEmpty).toList();
    final nextAttempt = _successfulGenerationAttempts + 1;

    _isLoading = true;
    _fetchError = null;
    notifyListeners();

    bool streamFlow = false;
    final streamed = <Recipe>[];

    try {
      final fetched = await _recipeRepo.fetchRecipes(
        excludeRecipeNames: excludeNames,
        userRefinementNote: refinementNote,
        generationAttempt: nextAttempt,
        onFlowSelected: (isStreaming) {
          streamFlow = isStreaming;
          _isStreamingFlow = isStreaming;
          notifyListeners();
        },
        onRecipe: (recipe) {
          streamed.add(recipe);
          final next = append
              ? _dedupeRecipesByNormalizedTitle([
                  ...prior,
                  ...streamed,
                ])
              : List<Recipe>.from(streamed);
          _recipes = next;
          notifyListeners();
        },
      );

      if (!streamFlow) {
        _recipes = append
            ? _dedupeRecipesByNormalizedTitle([...prior, ...fetched])
            : fetched;
      }
      _successfulGenerationAttempts = nextAttempt;
      _fetchError = null;
    } catch (e, st) {
      _recipes = prior;
      _fetchError = recipeFetchErrorMessage(e);
      if (_kRecipeLogging) {
        debugPrint('[RecipeViewModel] fetchMoreRecipes failed: $e');
        debugPrint('$st');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void scheduleLifestyleSync() {
    unawaited(_userRepo.syncLifestyleFromPrefs());
  }

  void clearRecipeGenerationState() {
    _fetchError = null;
    _recipes = [];
    _successfulGenerationAttempts = 0;
    notifyListeners();
  }

  void setBeingEdited() {
    _isBeingEdited = true;
    notifyListeners();
  }

  void replaceRecipeInGeneratedList(Recipe updated) {
    final id = updated.recipeId;
    _recipes = _recipes.map((r) => r.recipeId == id ? updated : r).toList();
    notifyListeners();
  }

  /// Toggles private Saved (bookmark) on the backend and updates [recipes].
  Future<bool> toggleSaved(Recipe recipe) async {
    final updated = recipe.copyWith(isSaved: !recipe.isSaved);
    try {
      await _telemetry.logFeatureInteraction(featureId: FeatureIds.toggleSave);
      await _userRepo.saveSavedRecipe(updated);
      _recipes = _recipes
          .map((r) => r.recipeId == updated.recipeId ? updated : r)
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggles public favorite (heart) for ranking. Requires recipe in Firestore.
  Future<bool> togglePublicFavorite(Recipe recipe) async {
    final next = !recipe.isFavorited;
    try {
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.togglePublicFavorite,
      );
      await _userRepo.togglePublicFavorite(
        recipe,
        favorited: next,
      );
      final nextCount = next
          ? recipe.favoriteCount + 1
          : (recipe.favoriteCount > 0 ? recipe.favoriteCount - 1 : 0);
      final updated = recipe.copyWith(
        isFavorited: next,
        favoriteCount: nextCount,
      );
      _recipes = _recipes
          .map((r) => r.recipeId == updated.recipeId ? updated : r)
          .toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  @Deprecated('Use toggleSaved and/or togglePublicFavorite')
  Future<bool> toggleFavorite(Recipe recipe) => toggleSaved(recipe);
}
