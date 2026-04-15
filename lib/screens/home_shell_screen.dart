import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../tutorial/coach_tour.dart';
import '../core/pantry_items.dart';
import '../view_models/home_view_model.dart';
import '../view_models/recipe_view_model.dart';
import '../widgets/favorite_recipes_list_view.dart';
import '../widgets/sous_chef_brand.dart';
import '../widgets/guest_signup_prompt.dart';
import 'recipe_flow_screen.dart';

/// Matches selected pantry pills and sheet highlights.
const Color _kPantrySelectedGreen = Color(0xFF2E7D32);

/// Main shell after login: bottom nav — Home, Create Recipes, Favorites.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.homeViewModel,
    required this.loginViewModel,
    required this.recipeViewModel,
    required this.sessionManager,
  });

  final HomeViewModel homeViewModel;
  final dynamic loginViewModel;
  final RecipeViewModel recipeViewModel;
  final dynamic sessionManager;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _coachNavKey = GlobalKey();
  final GlobalKey _coachGetRecipesKey = GlobalKey();
  final GlobalKey _coachAddPantryKey = GlobalKey();
  final GlobalKey _coachFavoritesKey = GlobalKey();
  late final CoachTourController _coachTour;

  int _currentIndex = 0;

  /// Bumped to remount embedded Create Recipes flow after generate-recipe error when user leaves the tab.
  int _embeddedRecipeFlowKey = 0;

  void _openAppDrawer() {
    _shellScaffoldKey.currentState?.openDrawer();
  }

  void _applyTabSideEffects(int index) {
    if (index == 1) {
      widget.sessionManager.savePreferenceSync('customPreference', '');
    }
    if (index == 2 && !widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadFavoritesFromApi();
    }
  }

  void _startCoachTour() {
    if (_coachTour.isActive) return;
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coachTour.start();
    });
  }

  void _onCoachNext() {
    if (!_coachTour.isActive) return;
    if (_coachTour.isLastStep) {
      _coachTour.finish();
      return;
    }
    final nextIdx = _coachTour.currentIndex + 1;
    final nextStep = _coachTour.steps[nextIdx];
    if (nextStep.tabIndex != null && nextStep.tabIndex != _currentIndex) {
      setState(() {
        _currentIndex = nextStep.tabIndex!;
        _applyTabSideEffects(_currentIndex);
      });
    }
    _coachTour.next();
  }

  void _onCoachBack() {
    if (!_coachTour.isActive || _coachTour.currentIndex <= 0) return;
    final prevIdx = _coachTour.currentIndex - 1;
    final prevStep = _coachTour.steps[prevIdx];
    if (prevStep.tabIndex != null && prevStep.tabIndex != _currentIndex) {
      setState(() {
        _currentIndex = prevStep.tabIndex!;
        _applyTabSideEffects(_currentIndex);
      });
    }
    _coachTour.previous();
  }

  void _onCoachSkip() {
    _coachTour.skip();
  }

  @override
  void initState() {
    super.initState();
    _coachTour = CoachTourController(
      steps: [
        CoachTourStep(
          targetKey: _coachNavKey,
          title: AppStrings.coachStepNavTitle,
          body: AppStrings.coachStepNavBody,
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: _coachGetRecipesKey,
          title: AppStrings.coachStepGetRecipesTitle,
          body: AppStrings.coachStepGetRecipesBody,
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: _coachAddPantryKey,
          title: AppStrings.coachStepAddPantryTitle,
          body: AppStrings.coachStepAddPantryBody,
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: _coachFavoritesKey,
          title: AppStrings.coachStepFavoritesTitle,
          body: AppStrings.coachStepFavoritesBody,
          tabIndex: 2,
        ),
      ],
    );
    widget.homeViewModel.addListener(_onHomeUpdate);
    widget.homeViewModel.loadUserDetails();
  }

  @override
  void dispose() {
    widget.homeViewModel.removeListener(_onHomeUpdate);
    _coachTour.dispose();
    super.dispose();
  }

  void _onHomeUpdate() {
    if (widget.homeViewModel.isSignedOut == true && mounted) {
      widget.homeViewModel.clearSignedOutFlag();
      widget.loginViewModel.setLoggedOut();
      context.go('/login');
    }
    if (mounted) setState(() {});
  }

  void _onTabTapped(int index) {
    final wasCreate = _currentIndex == 1;
    if (wasCreate && index != 1) {
      final err = widget.recipeViewModel.fetchError;
      if (err != null && err.isNotEmpty) {
        widget.recipeViewModel.clearRecipeGenerationState();
        setState(() {
          _embeddedRecipeFlowKey++;
          _currentIndex = index;
        });
        if (index == 2 && !widget.sessionManager.isGuestMode()) {
          widget.homeViewModel.loadFavoritesFromApi();
        }
        return;
      }
    }
    setState(() => _currentIndex = index);
    if (index == 1) {
      // Create Recipes uses mood/diet/cuisine only — ignore Home "Generate from text" session value.
      widget.sessionManager.savePreferenceSync('customPreference', '');
    }
    if (index == 2 && !widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadFavoritesFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        final userData = widget.homeViewModel.userData;
        final isGuest = widget.sessionManager.isGuestMode();
        return Stack(
          fit: StackFit.expand,
          children: [
            Scaffold(
              key: _shellScaffoldKey,
              drawer: Drawer(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DrawerHeader(
                        margin: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              AppStrings.appName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.tutorialDrawerSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: const Text(AppStrings.howToUse),
                        onTap: () async {
                          Navigator.of(context).pop();
                          final startCoach =
                              await context.push<bool>('/tutorial');
                          if (!context.mounted) return;
                          if (startCoach == true) _startCoachTour();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.touch_app_outlined),
                        title: const Text(AppStrings.showMeAround),
                        onTap: () {
                          Navigator.of(context).pop();
                          _startCoachTour();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              appBar: _currentIndex == 1
                  ? null
                  : AppBar(
                      automaticallyImplyLeading: false,
                      centerTitle: _currentIndex == 0,
                      leading: _currentIndex == 0 || _currentIndex == 2
                          ? IconButton(
                              icon: const Icon(Icons.menu),
                              tooltip: AppStrings.appMenuTooltip,
                              onPressed: _openAppDrawer,
                            )
                          : null,
                      title: _currentIndex == 0
                          ? const SousChefInlineTitle(markSize: 52)
                          : Text(_appBarTitle),
                      actions: [
                        if (!isGuest)
                          IconButton(
                            icon: const Icon(Icons.person),
                            onPressed: () => context.push('/profile'),
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: isGuest ? 'Exit guest mode' : 'Log out',
                          onPressed: () => widget.homeViewModel.signOut(),
                        ),
                      ],
                    ),
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _HomeTabBody(
                    homeViewModel: widget.homeViewModel,
                    recipeViewModel: widget.recipeViewModel,
                    sessionManager: widget.sessionManager,
                    coachGetRecipesKey: _coachGetRecipesKey,
                    coachAddPantryKey: _coachAddPantryKey,
                  ),
                  RecipeFlowScreen(
                    key: ValueKey<int>(_embeddedRecipeFlowKey),
                    userData: userData,
                    recipeViewModel: widget.recipeViewModel,
                    sessionManager: widget.sessionManager,
                    embedInTab: true,
                    onOpenAppMenu: _openAppDrawer,
                  ),
                  _FavoritesTabBody(
                    homeViewModel: widget.homeViewModel,
                    recipeViewModel: widget.recipeViewModel,
                    isGuest: isGuest,
                    coachFavoritesKey: _coachFavoritesKey,
                  ),
                ],
              ),
              bottomNavigationBar: KeyedSubtree(
                key: _coachNavKey,
                child: NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.restaurant_outlined),
                      selectedIcon: Icon(Icons.restaurant),
                      label: 'Create Recipes',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_outline),
                      selectedIcon: Icon(Icons.favorite),
                      label: 'Favorites',
                    ),
                  ],
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _coachTour,
              builder: (_, __) {
                if (!_coachTour.isActive) return const SizedBox.shrink();
                return CoachMarkOverlay(
                  controller: _coachTour,
                  onNext: _onCoachNext,
                  onBack: _onCoachBack,
                  onSkip: _onCoachSkip,
                );
              },
            ),
          ],
        );
      },
    );
  }

  String get _appBarTitle {
    switch (_currentIndex) {
      case 0:
        return AppStrings.appName;
      case 2:
        return 'Favorites';
      default:
        return AppStrings.appName;
    }
  }
}

class _HomeTabBody extends StatefulWidget {
  const _HomeTabBody({
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.sessionManager,
    required this.coachGetRecipesKey,
    required this.coachAddPantryKey,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final dynamic sessionManager;
  final GlobalKey coachGetRecipesKey;
  final GlobalKey coachAddPantryKey;

  @override
  State<_HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<_HomeTabBody> {
  late final TextEditingController _customPreferenceController;

  List<String> get _cuisineOptionsForUsualCuisines {
    // "Surprise Me" isn't a meaningful "usual cuisine" preference.
    return AppStrings.cuisineOptions
        .where((c) => c != AppStrings.surpriseMe)
        .toList();
  }

  String? _greetingName() {
    final name = widget.homeViewModel.sessionProfile.firstNameForDisplay.trim();
    if (name.isNotEmpty) return name;
    return null;
  }

  void _persistPrompt() {
    widget.sessionManager.savePreferenceSync(
      'customPreference',
      _customPreferenceController.text.trim(),
    );
  }

  void _togglePantryItem(String item) {
    final list = List<String>.from(widget.sessionManager.getIngredients());
    if (list.contains(item)) {
      list.remove(item);
    } else {
      list.add(item);
    }
    widget.sessionManager.saveIngredientsSync(list);
    setState(() {});
  }

  Future<void> _showUsualCuisinesBottomSheet() async {
    final current = widget.sessionManager.getUsualCuisines().toSet();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text('Cuisines you usually cook'),
                      subtitle: Text(
                        current.isEmpty
                            ? 'Pick one or more cuisines to personalize pantry suggestions.'
                            : current.join(', '),
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final cuisine in _cuisineOptionsForUsualCuisines)
                            CheckboxListTile(
                              value: current.contains(cuisine),
                              title: Text(cuisine),
                              onChanged: (_) {
                                if (current.contains(cuisine)) {
                                  current.remove(cuisine);
                                } else {
                                  current.add(cuisine);
                                }
                                widget.sessionManager
                                    .saveUsualCuisinesSync(current.toList());
                                setSheetState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _showPantryPickerBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return _PantryPickerSheet(
          sessionManager: widget.sessionManager,
          initialSelected: widget.sessionManager.getIngredients(),
          cuisines: widget.sessionManager.getUsualCuisines(),
        );
      },
    );
    if (!mounted) return;
    setState(() {});
  }

  void _showPantryStaplesInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.pantryStaplesDialogTitle),
        content: const Text(AppStrings.pantryStaplesInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _customPreferenceController = TextEditingController(
      text: widget.sessionManager.getPreference('customPreference') ?? '',
    );
    _customPreferenceController.addListener(() {
      setState(() {});
      _persistPrompt();
    });
  }

  @override
  void dispose() {
    _customPreferenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greetingName();
    final colorScheme = Theme.of(context).colorScheme;
    final selected = widget.sessionManager.getIngredients().toSet();
    final usualCuisines = widget.sessionManager.getUsualCuisines().toSet();
    final suggestedQuickChips =
        PantryItems.suggestedForCuisines(usualCuisines.toList(), limit: 24);
    final selectedSorted = List<String>.from(selected)..sort();
    final suggestionChipsOnly =
        suggestedQuickChips.where((item) => !selected.contains(item)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              if (greeting != null)
                Text(
                  'Hello, $greeting',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              if (greeting != null) const SizedBox(height: 24),
              Text(
                AppStrings.letsCookSomethingNice,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _customPreferenceController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: AppStrings.whatDoYouFeelLikeEating,
                  border: OutlineInputBorder(),
                  hintText: 'e.g. something light, pasta, curry',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                key: widget.coachGetRecipesKey,
                onPressed: () async {
                  final freeText = _customPreferenceController.text.trim();
                  final hasIngredients =
                      widget.sessionManager.getIngredients().isNotEmpty;
                  if (freeText.isEmpty && !hasIngredients) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter what you feel like eating, pick pantry items, or use the Create Recipes tab for preferences.',
                        ),
                      ),
                    );
                    return;
                  }
                  if (widget.sessionManager.isGuestMode() &&
                      await widget.sessionManager
                          .isGuestRecipeQuotaExceededForToday()) {
                    if (!context.mounted) return;
                    final goSignup =
                        await showGuestRecipeLimitReachedDialog(context);
                    if (!context.mounted) return;
                    if (goSignup == true) goToSignup(context);
                    return;
                  }
                  if (!context.mounted) return;
                  context.push('/recipe-flow', extra: {
                    'userData': widget.homeViewModel.userData,
                    if (freeText.isNotEmpty) 'initialPrompt': freeText,
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get me Recipes'),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerHighest,
                child: ListTile(
                  title: const Text('Cuisines you usually cook'),
                  subtitle: Text(
                    usualCuisines.isEmpty
                        ? 'Tap to choose cuisines (for better pantry suggestions).'
                        : usualCuisines.join(', '),
                  ),
                  trailing: const Icon(Icons.tune),
                  onTap: _showUsualCuisinesBottomSheet,
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  children: [
                    const TextSpan(text: AppStrings.pantryStaples),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: Transform.translate(
                        offset: const Offset(3, -6),
                        child: Tooltip(
                          message: AppStrings.pantryStaplesInfoIconTooltip,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showPantryStaplesInfoDialog,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 4,
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton.icon(
                  key: widget.coachAddPantryKey,
                  onPressed: _showPantryPickerBottomSheet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add pantry items'),
                ),
              ),
              const SizedBox(height: 10),
              if (selectedSorted.isNotEmpty) ...[
                Text(
                  'In your pantry',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final item in selectedSorted)
                      _PantryPill(
                        label: item,
                        selected: true,
                        colorScheme: colorScheme,
                        onTap: () => _togglePantryItem(item),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (suggestionChipsOnly.isNotEmpty) ...[
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final item in suggestionChipsOnly)
                    _PantryPill(
                      label: item,
                      selected: false,
                      colorScheme: colorScheme,
                      onTap: () => _togglePantryItem(item),
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantryPickerSheet extends StatefulWidget {
  const _PantryPickerSheet({
    required this.sessionManager,
    required this.initialSelected,
    required this.cuisines,
  });

  final dynamic sessionManager;
  final List<String> initialSelected;
  final List<String> cuisines;

  @override
  State<_PantryPickerSheet> createState() => _PantryPickerSheetState();
}

class _PantryPickerSheetState extends State<_PantryPickerSheet> {
  late final TextEditingController _controller;
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _selected = widget.initialSelected.toSet();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _normalizeCustomIngredient(String raw) => raw.trim();

  static bool _containsCaseInsensitive(Iterable<String> list, String value) {
    final v = value.trim().toLowerCase();
    for (final item in list) {
      if (item.trim().toLowerCase() == v) return true;
    }
    return false;
  }

  void _toggle(String item) {
    if (_selected.contains(item)) {
      _selected.remove(item);
    } else {
      _selected.add(item);
    }
    widget.sessionManager.saveIngredientsSync(_selected.toList());
    setState(() {});
  }

  void _addCustom(String raw) {
    final normalized = _normalizeCustomIngredient(raw);
    if (normalized.isEmpty) return;
    if (_containsCaseInsensitive(_selected, normalized)) return;
    _selected.add(normalized);
    widget.sessionManager.saveIngredientsSync(_selected.toList());
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();
    final filtered = query.isEmpty
        ? const <String>[]
        : PantryItems.allItems
            .where((e) => e.toLowerCase().contains(query.toLowerCase()))
            .toList();

    final canAddCustom = query.isNotEmpty &&
        query.length <= 40 &&
        !_containsCaseInsensitive(PantryItems.allItems, query) &&
        !_containsCaseInsensitive(_selected, query);

    final suggestionCuisines = widget.cuisines.isEmpty
        ? const [PantryItems.cuisinePopular]
        : widget.cuisines;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search pantry items',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Your pantry',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_selected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Nothing selected yet — pick below or search.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item
                              in (List<String>.from(_selected)..sort()))
                            InputChip(
                              label: Text(item),
                              onDeleted: () => _toggle(item),
                              deleteIconColor: Colors.white,
                              backgroundColor: _kPantrySelectedGreen,
                              labelStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide.none,
                            ),
                        ],
                      ),
                    ),
                  if (canAddCustom)
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text('Add "$query"'),
                      onTap: () => _addCustom(query),
                    ),
                  if (filtered.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 8, bottom: 6),
                      child: Text(
                        'Search results',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        checkboxTheme: CheckboxThemeData(
                          fillColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return _kPantrySelectedGreen;
                            }
                            return null;
                          }),
                          checkColor: WidgetStateProperty.all(Colors.white),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in filtered)
                            CheckboxListTile(
                              value: _selected.contains(item),
                              title: Text(item),
                              onChanged: (_) => _toggle(item),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(
                      'Suggested for you',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  for (final cuisine in suggestionCuisines) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 6),
                      child: Text(
                        cuisine,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final item
                            in (PantryItems.staplesByCuisine[cuisine] ??
                                const <String>[]))
                          Builder(
                            builder: (ctx) {
                              final sel = _selected.contains(item);
                              return FilterChip(
                                label: Text(
                                  item,
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Theme.of(ctx).colorScheme.onSurface,
                                    fontWeight:
                                        sel ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                                selected: sel,
                                showCheckmark: true,
                                checkmarkColor: Colors.white,
                                selectedColor: _kPantrySelectedGreen,
                                backgroundColor: Theme.of(ctx)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                side: BorderSide.none,
                                onSelected: (_) => _toggle(item),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  _selected.isEmpty
                      ? 'Done'
                      : 'Done (${_selected.length} selected)',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single pantry staple pill (neutral or green when selected).
class _PantryPill extends StatelessWidget {
  const _PantryPill({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  static const double _pillHeight = 44;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: SizedBox(
        height: _pillHeight,
        child: Material(
          elevation: selected ? 1 : 2,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(22),
          color: selected
              ? _kPantrySelectedGreen
              : colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? Colors.white : colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesTabBody extends StatelessWidget {
  const _FavoritesTabBody({
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.isGuest,
    required this.coachFavoritesKey,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final bool isGuest;
  final GlobalKey coachFavoritesKey;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: coachFavoritesKey,
      child: FavoriteRecipesListView(
        homeViewModel: homeViewModel,
        recipeViewModel: recipeViewModel,
        isGuest: isGuest,
        onGuestSignUpTap: () => goToSignup(context),
      ),
    );
  }
}
