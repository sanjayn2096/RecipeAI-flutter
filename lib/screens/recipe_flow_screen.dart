import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../core/app_strings.dart';
import '../core/constants.dart';
import '../data/models/user_data.dart';
import '../services/session_manager.dart';
import '../widgets/cartoon_outlined_card.dart';
import '../widgets/guest_signup_prompt.dart';
import '../widgets/recipe_list_row.dart';
import '../widgets/recipe_search_context_banner.dart';
import '../widgets/sous_chef_menu_button.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/recipe_view_model.dart';

import 'prompt_screen.dart';

class RecipeFlowScreen extends StatefulWidget {
  const RecipeFlowScreen({
    super.key,
    required this.userData,
    this.initialPrompt,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.sessionManager,
    this.embedInTab = false,
    this.onOpenAppMenu,
  });

  final UserData? userData;
  /// When set (e.g. from Home "What do you feel like eating?"), skip mood/diet/cuisine and call generate-recipe API.
  final String? initialPrompt;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final dynamic sessionManager;
  /// When true (bottom tab), back from recipe list resets the flow instead of popping a route.
  final bool embedInTab;
  /// Opens the parent [HomeShellScreen] drawer (nested scaffolds cannot use [Scaffold.of] for the shell).
  final VoidCallback? onOpenAppMenu;

  @override
  State<RecipeFlowScreen> createState() => _RecipeFlowScreenState();
}

typedef _FetchMoreRecipesResult = ({bool append, String? refinement});

class _RecipeFlowScreenState extends State<RecipeFlowScreen> {
  String _currentRoute = 'mood';
  final TextEditingController _fetchMorePreferenceController =
      TextEditingController();

  List<Widget> _embedShellMenuActions() {
    if (!widget.embedInTab || widget.onOpenAppMenu == null) {
      return const <Widget>[];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Center(
          child: SousChefMenuButton(
            tooltip: AppStrings.appMenuTooltip,
            onPressed: widget.onOpenAppMenu!,
          ),
        ),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapInitialRoute();
    });
  }

  Future<void> _bootstrapInitialRoute() async {
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      if (!await _ensureGuestCanGenerate(popRouteWhenBlocked: !widget.embedInTab)) {
        return;
      }
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[RecipeFlowScreen] bootstrap: saving "${widget.initialPrompt}" as customPreference, then calling BACKEND',
        );
      }
      widget.sessionManager
          .savePreferenceSync('customPreference', widget.initialPrompt!);
      setState(() => _currentRoute = 'recipeActivity');
      widget.recipeViewModel.fetchRecipesFromPrompt();
      return;
    }
    if (!widget.embedInTab &&
        widget.sessionManager.getIngredients().isNotEmpty) {
      if (!await _ensureGuestCanGenerate(popRouteWhenBlocked: !widget.embedInTab)) {
        return;
      }
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[RecipeFlowScreen] bootstrap: ingredients only -> backend generate-recipe',
        );
      }
      widget.sessionManager.savePreferenceSync('customPreference', '');
      setState(() => _currentRoute = 'recipeActivity');
      widget.recipeViewModel.fetchRecipesFromPrompt();
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[RecipeFlowScreen] bootstrap: mood/diet/cuisine flow, then backend generate-recipe',
      );
    }
  }

  /// Returns false if guest is over quota (dialog; optional pop for blocked entry from Home).
  Future<bool> _ensureGuestCanGenerate({bool popRouteWhenBlocked = false}) async {
    final sm = widget.sessionManager;
    if (!sm.isGuestMode()) return true;
    if (!(await sm.isGuestRecipeQuotaExceededForToday())) return true;
    if (!mounted) return false;
    final goSignup = await showGuestRecipeLimitReachedDialog(context);
    if (!mounted) return false;
    if (goSignup == true) goToSignup(context);
    if (popRouteWhenBlocked && !widget.embedInTab && context.mounted) {
      context.pop();
    }
    return false;
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
    Future(() async {
      if (!await _ensureGuestCanGenerate()) return;
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[RecipeFlowScreen] _goToRecipeActivity: calling backend generate-recipe (fetchRecipes)',
        );
      }
      _clearCustomPreferenceForEmbeddedCreateFlow();
      final recipeVm = widget.recipeViewModel as RecipeViewModel;
      recipeVm.scheduleLifestyleSync();
      recipeVm.fetchRecipes();
      setState(() => _currentRoute = 'recipeActivity');
    });
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

  void _hydrateQuestionnaireSelectionsFromSession() {
    final sm = widget.sessionManager as SessionManager;
    _selectedMood = sm.getPreference(AppConstants.prefsMood);
    _selectedDiet = sm.getPreference(AppConstants.prefsDietRestrictions);
    _selectedCuisine = sm.getPreference(AppConstants.prefsCuisine);
    _selectedCooking =
        sm.getPreference(AppConstants.prefsCookingPreference);
  }

  void _editSearchSettingsFromResultsList() {
    setState(() {
      _hydrateQuestionnaireSelectionsFromSession();
      _currentRoute = 'mood';
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
  void dispose() {
    _fetchMorePreferenceController.dispose();
    super.dispose();
  }

  Future<void> _showFetchMoreRecipesSheet() async {
    if (!await _ensureGuestCanGenerate()) return;
    if (!mounted) return;
    _fetchMorePreferenceController.clear();
    final result = await showModalBottomSheet<_FetchMoreRecipesResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _FetchMoreRecipesSheet(
        preferenceController: _fetchMorePreferenceController,
      ),
    );
    if (result == null || !mounted) return;
    final recipeVm = widget.recipeViewModel as RecipeViewModel;
    await recipeVm.fetchMoreRecipes(
      append: result.append,
      refinementNote: result.refinement,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoute == 'recipeActivity') {
      return ListenableBuilder(
        listenable: widget.recipeViewModel,
        builder: (_, __) {
          final recipes = widget.recipeViewModel.recipes;
          final isLoading = widget.recipeViewModel.isLoading == true;
          final isStreaming = widget.recipeViewModel.isStreamingFlow == true;

          if (isLoading && recipes.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(AppStrings.fetchRecipes),
                actions: _embedShellMenuActions(),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      child: Lottie.asset(
                        'assets/animations/cooking_animation.json',
                        repeat: true,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isStreaming
                          ? 'Streaming recipes... first results should appear quickly'
                          : AppStrings.sendingTastyRecipes,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          if (recipes.isEmpty) {
            final err = widget.recipeViewModel.fetchError as String?;
            final isError = err != null && err.isNotEmpty;
            return Scaffold(
              appBar: AppBar(
                title: const Text(AppStrings.fetchRecipes),
                actions: _embedShellMenuActions(),
              ),
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
                        onPressed: () async {
                          if (kDebugMode) {
                            debugPrint(
                              '[RecipeFlowScreen] Empty/error refresh: generate-recipe again',
                            );
                          }
                          if (!await _ensureGuestCanGenerate()) return;
                          if (!mounted) return;
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
          final batchRefreshOverlay =
              isLoading && recipes.isNotEmpty && !isStreaming;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Recipes'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.embedInTab
                    ? _resetFlowToStart
                    : () => context.pop(),
              ),
              actions: _embedShellMenuActions(),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.sessionManager.isGuestMode()) ...[
                    Text(
                      AppStrings.guestQuotaEachGenerationCounts,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  FilledButton.icon(
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text(AppStrings.getDifferentRecipes),
                    onPressed: isLoading
                        ? null
                        : _showFetchMoreRecipesSheet,
                  ),
                ],
              ),
            ),
            body: Stack(
              children: [
                Column(
                  children: [
                    if (isLoading && isStreaming)
                      const LinearProgressIndicator(minHeight: 2),
                    if (isLoading && isStreaming)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Text(
                          'Loading more recipes...',
                          style:
                              Theme.of(context).textTheme.bodySmall ??
                              const TextStyle(fontSize: 13),
                        ),
                      ),
                    RecipeSearchContextBanner(
                      sessionManager: widget.sessionManager as SessionManager,
                      onChangeSearchSettings:
                          _editSearchSettingsFromResultsList,
                    ),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: batchRefreshOverlay,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          itemCount: recipes.length,
                          itemBuilder: (_, i) {
                            final recipe = recipes[i];
                            return CartoonOutlinedCard(
                              child: RecipeListRow(
                                recipe: recipe,
                                trailingActions: [
                                  IconButton(
                                    tooltip: recipe.isSaved
                                        ? 'Remove from saved'
                                        : 'Save to your list',
                                    icon: Icon(
                                      recipe.isSaved
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color: recipe.isSaved
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    onPressed: () async {
                                      if ((widget.sessionManager
                                              as SessionManager)
                                          .isGuestMode()) {
                                        final goSignup =
                                            await showGuestFavoriteSignupDialog(
                                                context);
                                        if (!context.mounted) return;
                                        if (goSignup == true) {
                                          goToSignup(context);
                                        }
                                        return;
                                      }
                                      await widget.recipeViewModel
                                          .toggleSaved(recipe);
                                    },
                                  ),
                                  IconButton(
                                    tooltip: recipe.isFavorited
                                        ? 'Remove public favorite'
                                        : 'Favorite (trending)',
                                    icon: Icon(
                                      recipe.isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: recipe.isFavorited
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                    onPressed: () async {
                                      if ((widget.sessionManager
                                              as SessionManager)
                                          .isGuestMode()) {
                                        final goSignup =
                                            await showGuestFavoriteSignupDialog(
                                                context);
                                        if (!context.mounted) return;
                                        if (goSignup == true) {
                                          goToSignup(context);
                                        }
                                        return;
                                      }
                                      if (recipe.recipeId.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Open the full recipe (saved) before favoriting',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      await widget.recipeViewModel
                                          .togglePublicFavorite(recipe);
                                    },
                                  ),
                                ],
                                onTap: () {
                                  context.push(
                                    '/show-recipe',
                                    extra: {
                                      'recipe': recipe,
                                      'recipeViewModel':
                                          widget.recipeViewModel,
                                      'groceryListViewModel':
                                          widget.groceryListViewModel,
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (batchRefreshOverlay)
                  Positioned.fill(
                    child: ColoredBox(
                      color:
                          Theme.of(context).colorScheme.scrim.withValues(
                                alpha: 0.32,
                              ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
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
      appBarActions: _embedShellMenuActions(),
    );
  }
}

class _FetchMoreRecipesSheet extends StatefulWidget {
  const _FetchMoreRecipesSheet({
    required this.preferenceController,
  });

  final TextEditingController preferenceController;

  @override
  State<_FetchMoreRecipesSheet> createState() =>
      _FetchMoreRecipesSheetState();
}

class _FetchMoreRecipesSheetState extends State<_FetchMoreRecipesSheet> {
  void _onTextChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.preferenceController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.preferenceController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _submitReplace() {
    FocusScope.of(context).unfocus();
    final t = widget.preferenceController.text.trim();
    Navigator.pop(
      context,
      (append: false, refinement: t.isEmpty ? null : t),
    );
  }

  void _submitAppend() {
    FocusScope.of(context).unfocus();
    final t = widget.preferenceController.text.trim();
    Navigator.pop(
      context,
      (append: true, refinement: t.isEmpty ? null : t),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final onSurface = scheme.onSurface;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: safeBottom + keyboardInset + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.fetchMoreRecipes,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.preferenceController,
                          autofocus: false,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                          cursorColor: onSurface,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            hintText: AppStrings.recipePreferencesOptionalHint,
                            hintStyle: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding:
                                const EdgeInsets.fromLTRB(12, 12, 8, 12),
                          ),
                        ),
                      ),
                      Material(
                        color: scheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _submitReplace,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.arrow_forward,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _submitAppend,
              child: Text(AppStrings.keepAndAddRecipes),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}
