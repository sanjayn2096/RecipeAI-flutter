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
    } else if (!widget.embedInTab &&
        widget.sessionManager.getIngredients().isNotEmpty) {
      // Home pushed `/recipe-flow` (pantry-only). Bottom-nav Create tab always starts questionnaire.
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

  void _goToPreviousQuestionnaireStep() {
    final prev = AppStrings.previousRoute(_currentRoute);
    if (prev != null) {
      setState(() => _currentRoute = prev);
    }
  }

  VoidCallback? get _promptOnBack {
    if (AppStrings.previousRoute(_currentRoute) != null) {
      return _goToPreviousQuestionnaireStep;
    }
    if (!widget.embedInTab) {
      return () {
        if (context.mounted) context.pop();
      };
    }
    return null;
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
            final err = widget.recipeViewModel.fetchError as String?;
            final isError = err != null && err.isNotEmpty;
            return Scaffold(
              appBar: AppBar(title: const Text(AppStrings.fetchRecipes)),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isError ? Icons.error_outline : Icons.restaurant_outlined,
                        size: 48,
                        color: isError
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isError ? 'Couldn’t load recipes' : 'No recipes yet',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isError
                            ? err
                            : 'Nothing came back this time. Tap Refresh to try again, '
                                'or use Back to adjust mood, diet, cuisine, or cooking time.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          if (kDebugMode) {
                            debugPrint(
                              '[RecipeFlowScreen] Empty/error refresh: generate-recipe again',
                            );
                          }
                          _clearCustomPreferenceForEmbeddedCreateFlow();
                          widget.recipeViewModel.fetchRecipes();
                        },
                        child: const Text(AppStrings.refresh),
                      ),
                    ],
                  ),
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
      onBack: _promptOnBack,
    );
  }
}
