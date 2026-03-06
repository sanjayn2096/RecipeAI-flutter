import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../data/models/recipe.dart';
import '../data/models/user_data.dart';

class RecipeFlowScreen extends StatefulWidget {
  const RecipeFlowScreen({
    super.key,
    required this.userData,
    required this.recipeViewModel,
    required this.sessionManager,
  });

  final UserData? userData;
  final dynamic recipeViewModel;
  final dynamic sessionManager;

  @override
  State<RecipeFlowScreen> createState() => _RecipeFlowScreenState();
}

class _RecipeFlowScreenState extends State<RecipeFlowScreen> {
  String _currentRoute = 'mood';
  String? _selectedMood;
  String? _selectedDiet;
  String? _selectedCuisine;
  String? _selectedCooking;

  List<String> get _optionsForRoute {
    switch (_currentRoute) {
      case 'mood':
        return AppStrings.moodOptions;
      case 'dietRestrictions':
        return AppStrings.dietOptions;
      case 'cuisinePreferences':
        return AppStrings.cuisineOptions;
      case 'cookingPreferences':
        return AppStrings.cookingTimeOptions;
      default:
        return [];
    }
  }

  String? get _selectedForRoute {
    switch (_currentRoute) {
      case 'mood':
        return _selectedMood;
      case 'dietRestrictions':
        return _selectedDiet;
      case 'cuisinePreferences':
        return _selectedCuisine;
      case 'cookingPreferences':
        return _selectedCooking;
      default:
        return null;
    }
  }

  void _selectOption(String option) {
    widget.sessionManager.savePreferenceSync(_currentRoute, option);
    setState(() {
      switch (_currentRoute) {
        case 'mood':
          _selectedMood = option;
          break;
        case 'dietRestrictions':
          _selectedDiet = option;
          break;
        case 'cuisinePreferences':
          _selectedCuisine = option;
          break;
        case 'cookingPreferences':
          _selectedCooking = option;
          break;
      }
    });
  }

  void _next() {
    if (_currentRoute == 'mood' &&
        _selectedMood == AppStrings.feelingLucky) {
      _goToRecipeActivity();
      return;
    }
    final nextRoute = AppStrings.nextRoute(_currentRoute);
    if (nextRoute == 'recipeActivity') {
      _goToRecipeActivity();
      return;
    }
    setState(() => _currentRoute = nextRoute ?? _currentRoute);
  }

  void _goToRecipeActivity() {
    widget.recipeViewModel.fetchRecipes();
    setState(() => _currentRoute = 'recipeActivity');
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoute == 'recipeActivity') {
      return ListenableBuilder(
        listenable: widget.recipeViewModel,
        builder: (_, __) {
          if (widget.recipeViewModel.isLoading) {
            return Scaffold(
              appBar: AppBar(title: const Text(AppStrings.fetchRecipes)),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(AppStrings.sendingTastyRecipes),
                  ],
                ),
              ),
            );
          }
          final recipes = widget.recipeViewModel.recipes;
          if (recipes.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text(AppStrings.fetchRecipes)),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No recipes found. Try again.'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => widget.recipeViewModel.fetchRecipes(),
                      child: const Text(AppStrings.refresh),
                    ),
                  ],
                ),
              ),
            );
          }
          return Scaffold(
            appBar: AppBar(
              title: const Text('Recipes'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            body: ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (_, i) {
                final recipe = recipes[i];
                return ListTile(
                  title: Text(recipe.recipeName),
                  subtitle: Text(recipe.cuisine),
                  trailing: IconButton(
                    icon: Icon(
                      recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () => widget.recipeViewModel.saveFavorite(recipe),
                  ),
                  onTap: () {
                    context.push(
                      '/show-recipe',
                      extra: {
                        'recipe': recipe,
                        'recipeViewModel': widget.recipeViewModel,
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      );
    }

    return PromptScreen(
      route: _currentRoute,
      options: _optionsForRoute,
      selectedOption: _selectedForRoute,
      onOptionSelected: _selectOption,
      onNext: _next,
    );
  }
}
