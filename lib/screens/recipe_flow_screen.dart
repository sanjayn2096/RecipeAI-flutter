import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../core/app_strings.dart';
import '../core/diet_allergy_options.dart';
import '../core/recipe_generation_entry_point.dart';
import '../data/models/user_data.dart';
import '../services/session_manager.dart';
import '../widgets/cartoon_outlined_card.dart';
import '../widgets/guest_signup_prompt.dart';
import '../widgets/recipe_list_row.dart';
import '../widgets/recipe_search_context_banner.dart';
import '../widgets/rotating_recipe_loading_message.dart';
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
    this.generationEntryPoint = RecipeGenerationEntryPoint.createRecipes,
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
  /// Generation started from Home (pushed flow) vs Create Recipes tab.
  final RecipeGenerationEntryPoint generationEntryPoint;

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
    _hydrateQuestionnaireSelectionsFromSession();
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
      widget.recipeViewModel.fetchRecipesFromPrompt(
        entryPoint: widget.generationEntryPoint,
      );
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
      widget.recipeViewModel.fetchRecipesFromPrompt(
        entryPoint: widget.generationEntryPoint,
      );
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

  void _persistCreateFlowSelection(String route, String option) {
    final sm = widget.sessionManager as SessionManager;
    switch (route) {
      case 'mood':
        sm.saveCreateFlowMoodSync(option);
        break;
      case 'dietRestrictions':
        sm.saveCreateFlowDietRestrictionsSync(option);
        break;
      case 'cuisinePreferences':
        sm.saveCreateFlowCuisineSync(option);
        break;
      case 'cookingPreferences':
        sm.saveCreateFlowCookingPreferenceSync(option);
        break;
      default:
        break;
    }
  }

  void _selectOption(String option) {
    _persistCreateFlowSelection(_currentRoute, option);
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
      recipeVm.fetchRecipes(entryPoint: widget.generationEntryPoint);
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
    _selectedMood = sm.getCreateFlowMood();
    _selectedDiet = sm.getCreateFlowDietRestrictions();
    _selectedCuisine = sm.getCreateFlowCuisine();
    _selectedCooking = sm.getCreateFlowCookingPreference();
  }

  Future<void> _showSearchSettingsSheet() async {
    if (!mounted) return;
    final vm = widget.recipeViewModel as RecipeViewModel;
    final ep = vm.lastGenerationEntryPoint ?? widget.generationEntryPoint;
    final lifestyleMode = ep == RecipeGenerationEntryPoint.home;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final sm = widget.sessionManager as SessionManager;
        if (lifestyleMode) {
          return _HomeLifestyleSearchSettingsSheet(
            sessionManager: sm,
            onSaved: () {
              vm.scheduleLifestyleSync();
              if (mounted) setState(() {});
            },
          );
        }
        return _CreateRecipesSearchSettingsSheet(
          sessionManager: sm,
          onSaved: () {
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  void _editSearchSettingsFromResultsList() {
    unawaited(_showSearchSettingsSheet());
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
                    RotatingRecipeLoadingMessage(isStreaming: isStreaming),
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
                          final vm = widget.recipeViewModel as RecipeViewModel;
                          vm.fetchRecipes(
                            entryPoint: vm.lastGenerationEntryPoint ??
                                widget.generationEntryPoint,
                          );
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
                      generationEntryPoint:
                          (widget.recipeViewModel as RecipeViewModel)
                                  .lastGenerationEntryPoint ??
                              widget.generationEntryPoint,
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

/// Create Recipes batch only — questionnaire-scoped prefs (same four steps as the tab flow).
class _CreateRecipesSearchSettingsSheet extends StatefulWidget {
  const _CreateRecipesSearchSettingsSheet({
    required this.sessionManager,
    required this.onSaved,
  });

  final SessionManager sessionManager;
  final VoidCallback onSaved;

  @override
  State<_CreateRecipesSearchSettingsSheet> createState() =>
      _CreateRecipesSearchSettingsSheetState();
}

class _CreateRecipesSearchSettingsSheetState
    extends State<_CreateRecipesSearchSettingsSheet> {
  late String _mood;
  late String _diet;
  late String _cuisine;
  late String _cooking;

  @override
  void initState() {
    super.initState();
    final sm = widget.sessionManager;
    _mood = sm.getCreateFlowMood();
    _diet = sm.getCreateFlowDietRestrictions();
    _cuisine = sm.getCreateFlowCuisine();
    _cooking = sm.getCreateFlowCookingPreference();
  }

  void _save() {
    final sm = widget.sessionManager;
    sm.saveCreateFlowMoodSync(_mood);
    sm.saveCreateFlowDietRestrictionsSync(_diet);
    sm.saveCreateFlowCuisineSync(_cuisine);
    sm.saveCreateFlowCookingPreferenceSync(_cooking);
    widget.onSaved();
    Navigator.pop(context);
  }

  Widget _radioRow(String title, List<String> options, String groupValue,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        ...options.map(
          (opt) => RadioListTile<String>(
            dense: true,
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            value: opt,
            groupValue: groupValue,
            onChanged: (v) {
              if (v != null) setState(() => onChanged(v));
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: safe + kb + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create Recipes preferences',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _radioRow(
              AppStrings.titleForRoute('mood'),
              AppStrings.moodOptions,
              _mood,
              (v) => _mood = v,
            ),
            _radioRow(
              AppStrings.titleForRoute('dietRestrictions'),
              AppStrings.dietOptions,
              _diet,
              (v) => _diet = v,
            ),
            _radioRow(
              AppStrings.titleForRoute('cuisinePreferences'),
              AppStrings.cuisineOptions,
              _cuisine,
              (v) => _cuisine = v,
            ),
            _radioRow(
              AppStrings.titleForRoute('cookingPreferences'),
              AppStrings.cookingTimeOptions,
              _cooking,
              (v) => _cooking = v,
            ),
            FilledButton(
              onPressed: _save,
              child: const Text(AppStrings.ok),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.back),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home-started batch — profile / lifestyle: diets, allergens, preferred cuisines, proficiency.
class _HomeLifestyleSearchSettingsSheet extends StatefulWidget {
  const _HomeLifestyleSearchSettingsSheet({
    required this.sessionManager,
    required this.onSaved,
  });

  final SessionManager sessionManager;
  final VoidCallback onSaved;

  @override
  State<_HomeLifestyleSearchSettingsSheet> createState() =>
      _HomeLifestyleSearchSettingsSheetState();
}

class _HomeLifestyleSearchSettingsSheetState
    extends State<_HomeLifestyleSearchSettingsSheet> {
  late Set<String> _dietProfiles;
  late String _dietRestrictionSummary;
  late Set<String> _allergensAvoid;
  late TextEditingController _allergyNotesController;
  late Set<String> _usualCuisines;
  late String _cookingProficiency;

  List<String> get _preferredCuisineOptions => AppStrings.cuisineOptions
      .where((c) => c != AppStrings.surpriseMe)
      .toList();

  @override
  void initState() {
    super.initState();
    final sm = widget.sessionManager;
    _dietProfiles = sm.getDietProfiles().toSet();
    final drRaw = sm.getLifestyleDietRestrictions();
    _dietRestrictionSummary = AppStrings.dietOptions.contains(drRaw)
        ? drRaw
        : AppStrings.noRestrictions;
    _allergensAvoid = sm.getAllergensAvoid().toSet();
    _allergyNotesController = TextEditingController(
      text: sm.getAllergyNotes() ?? '',
    );
    _usualCuisines = sm.getUsualCuisines().toSet();
    final cook = sm.getLifestyleCookingPreference();
    _cookingProficiency =
        AppStrings.cookingTimeOptions.contains(cook) ? cook : AppStrings.notParticular;
  }

  @override
  void dispose() {
    _allergyNotesController.dispose();
    super.dispose();
  }

  void _toggleDietProfile(String label) {
    setState(() {
      if (_dietProfiles.contains(label)) {
        _dietProfiles.remove(label);
      } else {
        _dietProfiles.add(label);
      }
    });
  }

  void _toggleAllergen(String label) {
    setState(() {
      if (_allergensAvoid.contains(label)) {
        _allergensAvoid.remove(label);
      } else {
        _allergensAvoid.add(label);
      }
    });
  }

  void _toggleUsualCuisine(String cuisine) {
    setState(() {
      if (_usualCuisines.contains(cuisine)) {
        _usualCuisines.remove(cuisine);
      } else {
        _usualCuisines.add(cuisine);
      }
    });
  }

  Future<void> _save() async {
    final sm = widget.sessionManager;
    await sm.saveDietProfiles(_dietProfiles.toList());
    sm.saveLifestyleDietRestrictionsSync(_dietRestrictionSummary);
    await sm.saveAllergensAvoid(_allergensAvoid.toList());
    final notes = _allergyNotesController.text.trim();
    await sm.saveAllergyNotes(notes.isEmpty ? null : notes);
    sm.saveUsualCuisinesSync(_usualCuisines.toList());
    sm.saveLifestyleCookingPreferenceSync(_cookingProficiency);
    widget.onSaved();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _sectionHeading(String title, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }

  Widget _cookingRadios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.homeSearchSettingsCookingProficiencyHeading,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.homeSearchSettingsCookingProficiencyHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        ...AppStrings.cookingTimeOptions.map(
          (opt) => RadioListTile<String>(
            dense: true,
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            value: opt,
            groupValue: _cookingProficiency,
            onChanged: (v) {
              if (v != null) setState(() => _cookingProficiency = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _dietRestrictionRadios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeading(
          AppStrings.homeSearchSettingsDietSummaryHeading,
          hint: AppStrings.homeSearchSettingsDietSummaryHint,
        ),
        const SizedBox(height: 8),
        ...AppStrings.dietOptions.map(
          (opt) => RadioListTile<String>(
            dense: true,
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            value: opt,
            groupValue: _dietRestrictionSummary,
            onChanged: (v) {
              if (v != null) setState(() => _dietRestrictionSummary = v);
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: safe + kb + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.homeSearchSettingsSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _sectionHeading(
              AppStrings.homeSearchSettingsDietsHeading,
              hint: AppStrings.homeSearchSettingsDietsHint,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DietAllergyOptions.dietMultiSelectOptions
                  .map(
                    (label) => FilterChip(
                      label: Text(label),
                      selected: _dietProfiles.contains(label),
                      onSelected: (_) => _toggleDietProfile(label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _dietRestrictionRadios(),
            const SizedBox(height: 8),
            _sectionHeading(
              AppStrings.homeSearchSettingsAllergensHeading,
              hint: AppStrings.homeSearchSettingsAllergensHint,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DietAllergyOptions.commonAllergens
                  .map(
                    (label) => FilterChip(
                      label: Text(label),
                      selected: _allergensAvoid.contains(label),
                      onSelected: (_) => _toggleAllergen(label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allergyNotesController,
              decoration: const InputDecoration(
                labelText: AppStrings.homeSearchSettingsAllergenNotesLabel,
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _sectionHeading(
              AppStrings.homeSearchSettingsPreferredCuisinesHeading,
              hint: AppStrings.homeSearchSettingsPreferredCuisinesHint,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _preferredCuisineOptions
                  .map(
                    (cuisine) => FilterChip(
                      label: Text(cuisine),
                      selected: _usualCuisines.contains(cuisine),
                      onSelected: (_) => _toggleUsualCuisine(cuisine),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _cookingRadios(),
            const SizedBox(height: 8),
            Text(
              DietAllergyOptions.medicalDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: const Text(AppStrings.ok),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.back),
            ),
          ],
        ),
      ),
    );
  }
}
