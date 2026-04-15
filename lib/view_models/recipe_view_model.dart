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

  /// Set when [fetchRecipes] fails; cleared on a new fetch start or success.
  String? _fetchError;
  String? get fetchError => _fetchError;

  bool _isBeingEdited = false;
  bool get isBeingEdited => _isBeingEdited;

  /// POST generate-recipe with structured session fields (server builds prompt).
  Future<void> fetchRecipes() async {
    if (_kRecipeLogging) debugPrint('[RecipeViewModel] fetchRecipes() -> backend generate-recipe');
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.generateRecipe,
      action: 'submit',
    );
    _isLoading = true;
    _fetchError = null;
    notifyListeners();
    try {
      _recipes = await _recipeRepo.fetchRecipes();
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

  /// Same as [fetchRecipes] — kept for call sites that name the “free text” flow explicitly.
  Future<void> fetchRecipesFromPrompt() => fetchRecipes();

  /// Clears recipes and last fetch error (e.g. after leaving Create Recipes tab on failure).
  void clearRecipeGenerationState() {
    _fetchError = null;
    _recipes = [];
    notifyListeners();
  }

  void setBeingEdited() {
    _isBeingEdited = true;
    notifyListeners();
  }

  /// Toggles favorite on the backend (`isFavorite` true = add, false = remove) and updates [recipes].
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
