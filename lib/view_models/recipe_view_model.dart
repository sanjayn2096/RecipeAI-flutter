import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/recipe_fetch_error_message.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/recipe.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';

bool _kRecipeLogging = kDebugMode;

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

  /// POST generate-recipe with structured session fields (server builds prompt).
  Future<void> fetchRecipes() async {
    if (_kRecipeLogging) {
      debugPrint('[RecipeViewModel] fetchRecipes() -> backend recipe generation flow');
    }
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
