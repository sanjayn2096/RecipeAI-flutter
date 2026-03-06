import 'package:flutter/foundation.dart';

import '../data/models/recipe.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';

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

  Future<void> fetchRecipes() async {
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

  void setBeingEdited() {
    _isBeingEdited = true;
    notifyListeners();
  }

  Future<void> saveFavorite(Recipe recipe) async {
    try {
      await _userRepo.saveFavoriteRecipe(recipe);
    } catch (_) {}
  }
}
