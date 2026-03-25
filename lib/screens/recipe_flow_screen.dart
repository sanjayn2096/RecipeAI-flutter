import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../data/models/user_data.dart';
import '../widgets/guest_signup_prompt.dart';

import 'prompt_screen.dart';

class RecipeFlowScreen extends StatefulWidget {
  const RecipeFlowScreen({
    super.key,
    required this.userData,
    this.initialPrompt,
    required this.recipeViewModel,
    required this.sessionManager,
    this.embedInTab = false,
  });

  final UserData? userData;
  /// When set (e.g. from Home "What do you feel like eating?"), skip mood/diet/cuisine and call generate-recipe API.
  final String? initialPrompt;
  final dynamic recipeViewModel;
  final dynamic sessionManager;
  /// When true (bottom tab), back from recipe list resets the flow instead of popping a route.
  final bool embedInTab;

  @override
  State<RecipeFlowScreen> createState() => _RecipeFlowScreenState();
}

class _RecipeFlowScreenState extends State<RecipeFlowScreen> {
  String _currentRoute = 'mood';

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[RecipeFlowScreen] initState: saving "${widget.initialPrompt}" as customPreference, then calling BACKEND with PromptBuilder prompt');
      }
      widget.sessionManager.savePreferenceSync('customPreference', widget.initialPrompt!);
      _currentRoute = 'recipeActivity';
      widget.recipeViewModel.fetchRecipesFromPrompt();
    } else if (widget.sessionManager.getIngredients().isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[RecipeFlowScreen] initState: ingredients only -> backend generate-recipe (PromptBuilder uses session ingredients)');
      }
      widget.sessionManager.savePreferenceSync('customPreference', '');
      _currentRoute = 'recipeActivity';
      widget.recipeViewModel.fetchRecipesFromPrompt();
    } else {
      if (kDebugMode) {
        debugPrint('[RecipeFlowScreen] initState: no initialPrompt -> mood/diet/cuisine flow, then backend generate-recipe');
      }
    }
  }
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

  /// Home "Generate from text" must not override the Create Recipes questionnaire.
  void _clearCustomPreferenceForEmbeddedCreateFlow() {
    if (widget.embedInTab) {
      widget.sessionManager.savePreferenceSync('customPreference', '');
    }
  }

  void _goToRecipeActivity() {
    if (kDebugMode) {
      debugPrint('[RecipeFlowScreen] _goToRecipeActivity: calling backend generate-recipe (fetchRecipes)');
    }
    _clearCustomPreferenceForEmbeddedCreateFlow();
    widget.recipeViewModel.fetchRecipes();
    setState(() => _currentRoute = 'recipeActivity');
  }

  void _resetFlowToStart() {
    setState(() {
      _currentRoute = 'mood';
      _selectedMood = null;
      _selectedDiet = null;
      _selectedCuisine = null;
      _selectedCooking = null;
    });
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
                      onPressed: () {
                        if (kDebugMode) {
                          debugPrint('[RecipeFlowScreen] Empty results refresh: calling backend generate-recipe again');
                        }
                        _clearCustomPreferenceForEmbeddedCreateFlow();
                        widget.recipeViewModel.fetchRecipes();
                      },
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
                onPressed: widget.embedInTab
                    ? _resetFlowToStart
                    : () => context.pop(),
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
                    tooltip: recipe.isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    icon: Icon(
                      recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: recipe.isFavorite
                          ? Colors.red
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () async {
                      if (widget.sessionManager.isGuestMode()) {
                        final goSignup =
                            await showGuestFavoriteSignupDialog(context);
                        if (!context.mounted) return;
                        if (goSignup == true) {
                          goToSignup(context);
                        }
                        return;
                      }
                      await widget.recipeViewModel.toggleFavorite(recipe);
                    },
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
