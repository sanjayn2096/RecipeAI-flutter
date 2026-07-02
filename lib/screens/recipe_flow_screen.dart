import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../core/l10n_context.dart';
import '../core/l10n_extensions.dart';
import '../core/monetization_navigation.dart';
import '../core/preference_options.dart';
import '../core/diet_allergy_options.dart';
import '../core/recipe_generation_entry_point.dart';
import '../data/models/user_data.dart';
import '../onboarding/onboarding_session_extension.dart';
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

  List<Widget> _embedShellMenuActions(BuildContext context) {
    if (!widget.embedInTab || widget.onOpenAppMenu == null) {
      return const <Widget>[];
    }
    return [
      Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Center(
          child: SousChefMenuButton(
            tooltip: context.l10n.appMenuTooltip,
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
    final isHomePushedFlow = !widget.embedInTab &&
        widget.generationEntryPoint == RecipeGenerationEntryPoint.home;
    final prompt = widget.initialPrompt?.trim() ?? '';

    if (isHomePushedFlow || prompt.isNotEmpty) {
      // Quota is enforced on Home before navigation; avoid popping this route here.
      if (!isHomePushedFlow &&
          !await _ensureGuestCanGenerate(popRouteWhenBlocked: false)) {
        return;
      }
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[RecipeFlowScreen] bootstrap: home generation '
          '(prompt="${prompt.isEmpty ? '(lifestyle/pantry)' : prompt}")',
        );
      }
      widget.sessionManager.savePreferenceSync('customPreference', prompt);
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

  /// Returns false if guest or free tier is over quota.
  Future<bool> _ensureGuestCanGenerate({bool popRouteWhenBlocked = false}) async {
    final sm = widget.sessionManager as SessionManager;
    if (sm.isGuestMode()) {
      if (!(await sm.isGuestRecipeQuotaExceededForToday())) return true;
      if (!mounted) return false;
      final action = await showGuestRecipeLimitReachedDialog(context);
      if (!mounted) return false;
      if (action == GuestLimitAction.signUp) goToSignup(context);
      if (popRouteWhenBlocked && !widget.embedInTab && context.mounted) {
        context.pop();
      }
      return false;
    }
    final isPremium = sm.readSubscriptionCacheSync().isPremium;
    if (!isPremium &&
        await sm.isSignedInFreeRecipeQuotaExceededForToday(
          isPremium: isPremium,
        )) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.freeTierQuotaMessage)),
      );
      openPremiumPaywall(
        context,
        source: 'free_quota',
        appTelemetry: (widget.recipeViewModel as RecipeViewModel).appTelemetry,
      );
      return false;
    }
    return true;
  }
  String? _selectedMood;
  String? _selectedDiet;
  String? _selectedCuisine;
  String? _selectedCooking;

  List<String> _optionsForRoute(BuildContext context) {
    final l10n = context.l10n;
    switch (_currentRoute) {
      case 'mood':
        return l10n.moodOptionKeys;
      case 'dietRestrictions':
        return l10n.dietOptionKeys;
      case 'cuisinePreferences':
        return l10n.cuisineOptionKeys;
      case 'cookingPreferences':
        return l10n.cookingTimeOptionKeys;
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
        PreferenceOptions.isFeelingLucky(_selectedMood)) {
      _goToRecipeActivity();
      return;
    }
    final nextRoute = context.l10n.nextRoute(_currentRoute);
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
            onSaved: _onSearchSettingsSaved,
          );
        }
        return _CreateRecipesSearchSettingsSheet(
          sessionManager: sm,
          onSaved: _onSearchSettingsSaved,
        );
      },
    );
  }

  /// Persists search settings are already saved by the sheet; re-run generation.
  Future<void> _onSearchSettingsSaved() async {
    final vm = widget.recipeViewModel as RecipeViewModel;
    final ep = vm.lastGenerationEntryPoint ?? widget.generationEntryPoint;
    if (ep == RecipeGenerationEntryPoint.home) {
      vm.scheduleLifestyleSync();
    }
    if (!mounted) return;
    setState(() {});
    if (!await _ensureGuestCanGenerate()) return;
    if (!mounted) return;
    _clearCustomPreferenceForEmbeddedCreateFlow();
    if (kDebugMode) {
      debugPrint(
        '[RecipeFlowScreen] Search settings saved: refreshing recipes (entry=$ep)',
      );
    }
    await vm.fetchRecipes(entryPoint: ep);
  }

  void _editSearchSettingsFromResultsList() {
    unawaited(_showSearchSettingsSheet());
  }

  void _goToPreviousQuestionnaireStep() {
    final prev = context.l10n.previousRoute(_currentRoute);
    if (prev != null) {
      setState(() => _currentRoute = prev);
    }
  }

  VoidCallback? get _promptOnBack {
    if (context.l10n.previousRoute(_currentRoute) != null) {
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
            final loadingReply =
                (widget.recipeViewModel as RecipeViewModel).assistantMessage
                    ?.trim();
            return Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.fetchRecipes),
                actions: _embedShellMenuActions(context),
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      if (loadingReply != null && loadingReply.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              loadingReply,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(height: 1.35),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }

          if (recipes.isEmpty) {
            final err = widget.recipeViewModel.fetchError as String?;
            final isError = err != null && err.isNotEmpty;
            return Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.fetchRecipes),
                actions: _embedShellMenuActions(context),
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isError
                            ? Icons.broken_image_outlined
                            : Icons.restaurant_outlined,
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
                      if (!isError)
                        Text(
                          'Nothing came back this time. Tap Refresh to try again, '
                          'or use Back to adjust mood, diet, cuisine, or cooking time.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                        child: Text(context.l10n.refresh),
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
              actions: _embedShellMenuActions(context),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.sessionManager.isGuestMode()) ...[
                    Text(
                      context.l10n.guestQuotaEachGenerationCounts,
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
                    label: Text(context.l10n.getDifferentRecipes),
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
                      assistantMessage:
                          (widget.recipeViewModel as RecipeViewModel)
                              .assistantMessage,
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
      options: _optionsForRoute(context),
      selectedOption: _selectedForRoute,
      onOptionSelected: _selectOption,
      onNext: _next,
      onBack: _promptOnBack,
      appBarActions: _embedShellMenuActions(context),
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
    final l10n = context.l10n;
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
              l10n.fetchMoreRecipes,
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
                            hintText: l10n.recipePreferencesOptionalHint,
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
              child: Text(l10n.keepAndAddRecipes),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
              child: Text(l10n.dismiss),
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
  final Future<void> Function() onSaved;

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

  Future<void> _save() async {
    final sm = widget.sessionManager;
    sm.saveCreateFlowMoodSync(_mood);
    sm.saveCreateFlowDietRestrictionsSync(_diet);
    sm.saveCreateFlowCuisineSync(_cuisine);
    sm.saveCreateFlowCookingPreferenceSync(_cooking);
    if (!mounted) return;
    Navigator.pop(context);
    await widget.onSaved();
  }

  Widget _radioRow(
    String title,
    List<String> optionKeys,
    String groupValue,
    String Function(String key) labelForKey,
    ValueChanged<String> onChanged,
  ) {
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
        ...optionKeys.map(
          (key) => RadioListTile<String>(
            dense: true,
            title: Text(labelForKey(key), style: const TextStyle(fontSize: 14)),
            value: key,
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
    final l10n = context.l10n;
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
              l10n.createRecipesPreferencesTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _radioRow(
              l10n.titleForRoute('mood'),
              l10n.moodOptionKeys,
              _mood,
              l10n.moodLabel,
              (v) => _mood = v,
            ),
            _radioRow(
              l10n.titleForRoute('dietRestrictions'),
              l10n.dietOptionKeys,
              _diet,
              l10n.dietLabel,
              (v) => _diet = v,
            ),
            _radioRow(
              l10n.titleForRoute('cuisinePreferences'),
              l10n.cuisineOptionKeys,
              _cuisine,
              l10n.cuisineLabel,
              (v) => _cuisine = v,
            ),
            _radioRow(
              l10n.titleForRoute('cookingPreferences'),
              l10n.cookingTimeOptionKeys,
              _cooking,
              l10n.cookingLabel,
              (v) => _cooking = v,
            ),
            FilledButton(
              onPressed: _save,
              child: Text(l10n.ok),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.back),
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
  final Future<void> Function() onSaved;

  @override
  State<_HomeLifestyleSearchSettingsSheet> createState() =>
      _HomeLifestyleSearchSettingsSheetState();
}

class _HomeLifestyleSearchSettingsSheetState
    extends State<_HomeLifestyleSearchSettingsSheet> {
  late Set<String> _dietProfiles;
  late Set<String> _allergensAvoid;
  late TextEditingController _allergyNotesController;
  late Set<String> _usualCuisines;
  late String _cookingProficiency;

  @override
  void initState() {
    super.initState();
    final sm = widget.sessionManager;
    _dietProfiles = sm.getDietProfiles().toSet();
    _allergensAvoid = sm.getAllergensAvoid().toSet();
    _allergyNotesController = TextEditingController(
      text: sm.getAllergyNotes() ?? '',
    );
    _usualCuisines = sm.getUsualCuisines().toSet();
    final cook = PreferenceOptions.normalizeCookingKey(
      sm.getLifestyleCookingPreference(),
    );
    _cookingProficiency = PreferenceOptions.cookingKeys.contains(cook)
        ? cook
        : PreferenceOptions.cookingNotParticular;
  }

  @override
  void dispose() {
    _allergyNotesController.dispose();
    super.dispose();
  }

  void _toggleDietProfile(String key) {
    setState(() {
      if (_dietProfiles.contains(key)) {
        _dietProfiles.remove(key);
      } else {
        _dietProfiles.add(key);
      }
    });
  }

  void _toggleAllergen(String key) {
    setState(() {
      if (_allergensAvoid.contains(key)) {
        _allergensAvoid.remove(key);
      } else {
        _allergensAvoid.add(key);
      }
    });
  }

  void _toggleUsualCuisine(String cuisineKey) {
    setState(() {
      if (_usualCuisines.contains(cuisineKey)) {
        _usualCuisines.remove(cuisineKey);
      } else {
        _usualCuisines.add(cuisineKey);
      }
    });
  }

  Future<void> _save() async {
    final sm = widget.sessionManager;
    await sm.saveDietProfiles(_dietProfiles.toList());
    sm.saveLifestyleDietRestrictionsSync(PreferenceOptions.dietNoRestrictions);
    await sm.saveAllergensAvoid(_allergensAvoid.toList());
    final notes = _allergyNotesController.text.trim();
    await sm.saveAllergyNotes(notes.isEmpty ? null : notes);
    sm.saveUsualCuisinesSync(_usualCuisines.toList());
    sm.saveLifestyleCookingPreferenceSync(_cookingProficiency);
    if (!mounted) return;
    Navigator.pop(context);
    await widget.onSaved();
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.homeSearchSettingsCookingProficiencyHeading,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.homeSearchSettingsCookingProficiencyHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 6),
        ...l10n.cookingTimeOptionKeys.map(
          (key) => RadioListTile<String>(
            dense: true,
            title: Text(
              l10n.cookingLabel(key),
              style: const TextStyle(fontSize: 14),
            ),
            value: key,
            groupValue: _cookingProficiency,
            onChanged: (v) {
              if (v != null) setState(() => _cookingProficiency = v);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferredCuisineKeys = l10n.preferredCuisineOptionKeys;
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
              l10n.homeSearchSettingsSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _sectionHeading(
              l10n.homeSearchSettingsDietsHeading,
              hint: l10n.homeSearchSettingsDietsHint,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DietAllergyOptions.dietMultiSelectOptionKeys
                  .map(
                    (key) => FilterChip(
                      label: Text(l10n.dietLabel(key)),
                      selected: _dietProfiles.contains(key),
                      onSelected: (_) => _toggleDietProfile(key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _sectionHeading(
              l10n.homeSearchSettingsAllergensHeading,
              hint: l10n.homeSearchSettingsAllergensHint,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DietAllergyOptions.commonAllergenKeys
                  .map(
                    (key) => FilterChip(
                      label: Text(l10n.allergenLabel(key)),
                      selected: _allergensAvoid.contains(key),
                      onSelected: (_) => _toggleAllergen(key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allergyNotesController,
              decoration: InputDecoration(
                labelText: l10n.homeSearchSettingsAllergenNotesLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _sectionHeading(
              l10n.homeSearchSettingsPreferredCuisinesHeading,
              hint: l10n.homeSearchSettingsPreferredCuisinesHint,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preferredCuisineKeys
                  .map(
                    (key) => FilterChip(
                      label: Text(l10n.cuisineLabel(key)),
                      selected: _usualCuisines.contains(key),
                      onSelected: (_) => _toggleUsualCuisine(key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _cookingRadios(),
            const SizedBox(height: 8),
            Text(
              l10n.medicalDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(l10n.ok),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.back),
            ),
          ],
        ),
      ),
    );
  }
}
