import 'package:flutter/foundation.dart';

import '../data/models/recipe.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';

bool _kRecipeLogging = kDebugMode;

class RecipeViewModel extends ChangeNotifier {
  RecipeViewModel({
    required RecipeRepository recipeRepository,
    required UserRepository userRepository,
  })  : _recipeRepo = recipeRepository,
        _userRepo = userRepository;

  final RecipeRepository _recipeRepo;
  final UserRepository _userRepo;

  List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isBeingEdited = false;
  bool get isBeingEdited => _isBeingEdited;

  /// POST generate-recipe (prompt from [PromptBuilder] / session).
  Future<void> fetchRecipes() async {
    if (_kRecipeLogging) debugPrint('[RecipeViewModel] fetchRecipes() -> backend generate-recipe');
    _isLoading = true;
    notifyListeners();
    try {
      _recipes = await _recipeRepo.fetchRecipes();
    } catch (_) {
      _recipes = [];
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Same as [fetchRecipes] — kept for call sites that name the “free text” flow explicitly.
  Future<void> fetchRecipesFromPrompt() => fetchRecipes();

  void setBeingEdited() {
    _isBeingEdited = true;
    notifyListeners();
  }

  /// Toggles favorite on the backend (`isFavorite` true = add, false = remove) and updates [recipes].
  Future<bool> toggleFavorite(Recipe recipe) async {
    final updated = recipe.copyWith(isFavorite: !recipe.isFavorite);
    try {
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
