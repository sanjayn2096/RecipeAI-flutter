import 'dart:math' show max, min, pi, sin;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../core/app_strings.dart';
import '../data/models/api_dtos.dart';
import '../data/models/session_profile.dart';
import '../data/models/user_data.dart';
import '../tutorial/coach_tour.dart';
import '../core/pantry_items.dart';
import '../view_models/home_view_model.dart';
import '../view_models/recipe_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/favorite_recipes_list_view.dart';
import '../widgets/sous_chef_brand.dart';
import '../widgets/sous_chef_menu_button.dart';
import '../widgets/guest_signup_prompt.dart';
import '../core/telemetry/app_telemetry.dart';
import 'grocery_list_screen.dart';
import 'recipe_flow_screen.dart';

/// Matches selected pantry pills and sheet highlights.
const Color _kPantrySelectedGreen = Color(0xFF2E7D32);

final List<PromptSuggestionItem> _kDemoPromptIdeas = <PromptSuggestionItem>[
  PromptSuggestionItem(
      text: 'Quick Indian Fish Curry', subtitle: 'Spicy • Easy'),
  PromptSuggestionItem(
      text: 'Creamy Mushroom Risotto', subtitle: 'Comfort • Medium'),
  PromptSuggestionItem(
      text: 'Greek Grilled Chicken', subtitle: 'High protein • Fast'),
  PromptSuggestionItem(
      text: 'Tofu Vegetable Stir Fry', subtitle: 'Vegan • Quick'),
  PromptSuggestionItem(
      text: 'Butter Chicken & Naan', subtitle: 'Classic • Rich'),
];

/// App bar: shared surface, [SousChefMenuButton], mark + "Sous Chef", profile initial + menu.
class _SousHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SousHomeAppBar({
    required this.onOpenMenu,
    required this.firstNameLetter,
    required this.isGuest,
    required this.onSignOut,
  });

  final VoidCallback onOpenMenu;
  final String firstNameLetter;
  final bool isGuest;
  final VoidCallback onSignOut;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      title: const SousChefInlineTitle(markSize: 44),
      leading: Center(
        child: SousChefMenuButton(
          tooltip: AppStrings.appMenuTooltip,
          onPressed: onOpenMenu,
        ),
      ),
      leadingWidth: 60,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 48),
            onSelected: (v) {
              if (v == 'profile' && !isGuest) {
                context.push('/profile');
              } else if (v == 'signout') {
                onSignOut();
              }
            },
            itemBuilder: (context) => [
              if (!isGuest)
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(
                value: 'signout',
                child: Text(isGuest ? 'Exit guest mode' : 'Log out'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primary,
                    child: Text(
                      firstNameLetter,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more, color: onSurface, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _firstNameLetterFromProfile(UserData? user, SessionProfile session) {
  final fromUser = (user?.firstName ?? '').trim();
  final name =
      fromUser.isNotEmpty ? fromUser : session.firstNameForDisplay.trim();
  if (name.isEmpty) return '?';
  return name.substring(0, 1).toUpperCase();
}

/// Main shell after login: bottom nav — Home, Create Recipes, Grocery list, Saved.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.homeViewModel,
    required this.loginViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.appTelemetry,
    required this.sessionManager,
  });

  final HomeViewModel homeViewModel;
  final dynamic loginViewModel;
  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final AppTelemetry appTelemetry;
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
    if (index == 3 && !widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadSavedFromApi();
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
          tabIndex: 3,
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
        if (index == 3 && !widget.sessionManager.isGuestMode()) {
          widget.homeViewModel.loadSavedFromApi();
        }
        return;
      }
    }
    setState(() => _currentIndex = index);
    if (index == 1) {
      // Create Recipes uses mood/diet/cuisine only — ignore Home "Generate from text" session value.
      widget.sessionManager.savePreferenceSync('customPreference', '');
    }
    if (index == 3 && !widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadSavedFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        final userData = widget.homeViewModel.userData;
        final isGuest = widget.sessionManager.isGuestMode();
        final colorScheme = Theme.of(context).colorScheme;
        final mediaW = MediaQuery.sizeOf(context).width;
        final cornerW = min(mediaW * 0.82, 620.0);
        final cornerH = min(mediaW * 1.02, 760.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: colorScheme.surface),
            if (_currentIndex == 0)
              Positioned(
                top: -120,
                right: -54,
                width: cornerW,
                height: cornerH,
                child: IgnorePointer(
                  child: _HomeCornerPhotoBlend(surface: colorScheme.surface),
                ),
              ),
            Scaffold(
              key: _shellScaffoldKey,
              backgroundColor:
                  _currentIndex == 0 ? Colors.transparent : colorScheme.surface,
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
                      ListTile(
                        leading: const Icon(Icons.shopping_cart_outlined),
                        title: const Text(AppStrings.groceryListDrawer),
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() => _currentIndex = 2);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              appBar: _currentIndex == 0
                  ? _SousHomeAppBar(
                      onOpenMenu: _openAppDrawer,
                      isGuest: isGuest,
                      firstNameLetter: isGuest
                          ? 'G'
                          : _firstNameLetterFromProfile(
                              widget.homeViewModel.userData,
                              widget.homeViewModel.sessionProfile,
                            ),
                      onSignOut: () => widget.homeViewModel.signOut(),
                    )
                  : _currentIndex == 1
                      ? null
                      : AppBar(
                          automaticallyImplyLeading: false,
                          centerTitle: false,
                          leading: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Align(
                              alignment: Alignment.center,
                              child: SousChefMenuButton(
                                tooltip: AppStrings.appMenuTooltip,
                                onPressed: _openAppDrawer,
                              ),
                            ),
                          ),
                          leadingWidth: 56,
                          title: Text(_appBarTitle),
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
                    groceryListViewModel: widget.groceryListViewModel,
                    sessionManager: widget.sessionManager,
                    embedInTab: true,
                    onOpenAppMenu: _openAppDrawer,
                  ),
                  GroceryListScreen(
                    groceryListViewModel: widget.groceryListViewModel,
                    appTelemetry: widget.appTelemetry,
                    embedInShell: true,
                  ),
                  _FavoritesTabBody(
                    homeViewModel: widget.homeViewModel,
                    recipeViewModel: widget.recipeViewModel,
                    groceryListViewModel: widget.groceryListViewModel,
                    isGuest: isGuest,
                    coachFavoritesKey: _coachFavoritesKey,
                  ),
                ],
              ),
              bottomNavigationBar: KeyedSubtree(
                key: _coachNavKey,
                child: NavigationBar(
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
                      icon: Icon(Icons.shopping_cart_outlined),
                      selectedIcon: Icon(Icons.shopping_cart),
                      label: 'Grocery',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bookmark_outline),
                      selectedIcon: Icon(Icons.bookmark),
                      label: 'Saved',
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
        return AppStrings.groceryListTitle;
      case 3:
        return 'Saved';
      default:
        return AppStrings.appName;
    }
  }
}

/// Frittata art in the top-right, faded into [surface] (alpha mask + soft color wash).
class _HomeCornerPhotoBlend extends StatelessWidget {
  const _HomeCornerPhotoBlend({required this.surface});

  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (Rect bounds) {
            return const RadialGradient(
              center: Alignment(1.0, -1.0),
              radius: 1.1,
              colors: <Color>[
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
                Color(0x4DFFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: <double>[0.0, 0.42, 0.68, 1.0],
            ).createShader(bounds);
          },
          child: const Opacity(
            opacity: 0.98,
            child: Image(
              image: AssetImage('assets/home_background_frittata.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topRight,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: const Alignment(0.58, 0.0),
                colors: <Color>[
                  surface.withValues(alpha: 0.62),
                  surface.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.7],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: const Alignment(0.0, -0.45),
                colors: <Color>[
                  surface.withValues(alpha: 0.5),
                  surface.withValues(alpha: 0.0),
                ],
                stops: const <double>[0.0, 0.62],
              ),
            ),
          ),
        ),
      ],
    );
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

  Future<void> _showPantryPickerBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return _PantryPickerSheet(
          sessionManager: widget.sessionManager,
          initialSelected: widget.sessionManager.getIngredients(),
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

  String _greetingLine() {
    final name = _greetingName();
    if (name != null) return 'Hello, $name';
    if (widget.sessionManager.isGuestMode()) return 'Hello, chef';
    return 'Hello';
  }

  void _applyFilterPhrase(String phrase) {
    _customPreferenceController.text = phrase;
    _customPreferenceController.selection = TextSelection.collapsed(
      offset: phrase.length,
    );
  }

  Future<void> _startRecipeFlow({String? promptOverride}) async {
    final freeText =
        (promptOverride ?? _customPreferenceController.text).trim();
    final hasIngredients = widget.sessionManager.getIngredients().isNotEmpty;
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
    if (widget.sessionManager.isGuestMode()) {
      final exceeded =
          await widget.sessionManager.isGuestRecipeQuotaExceededForToday();
      if (!mounted) return;
      if (exceeded) {
        final goSignup = await showGuestRecipeLimitReachedDialog(context);
        if (!mounted) return;
        if (goSignup == true) goToSignup(context);
        return;
      }
    }
    if (!mounted) return;
    context.push('/recipe-flow', extra: {
      'userData': widget.homeViewModel.userData,
      if (freeText.isNotEmpty) 'initialPrompt': freeText,
    });
  }

  Future<void> _onGetRecipesPressed() => _startRecipeFlow();

  Future<void> _onIdeaSelected(String prompt) =>
      _startRecipeFlow(promptOverride: prompt);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = widget.sessionManager.getIngredients().toSet();
    final selectedSorted = List<String>.from(selected)..sort();
    const horizontalPad = 20.0;
    const maxHomeContentWidth = 900.0;
    final innerW = MediaQuery.sizeOf(context).width - 2 * horizontalPad;
    final maxWidth = min(maxHomeContentWidth, max(0.0, innerW));
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: horizontalPad),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _HomeHeroRow(greetingLine: _greetingLine()),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => context.push('/trending'),
                  icon: const Icon(Icons.trending_up),
                  label: const Text('See trending recipes'),
                ),
              ),
              const SizedBox(height: 12),
              _HomeSearchField(
                controller: _customPreferenceController,
                onGo: _onGetRecipesPressed,
                coachGetRecipesKey: widget.coachGetRecipesKey,
              ),
              const SizedBox(height: 16),
              _HomeFilterChips(
                onSelect: _applyFilterPhrase,
              ),
              const SizedBox(height: 20),
              _PantryHintBar(
                coachAddPantryKey: widget.coachAddPantryKey,
                colorScheme: colorScheme,
                onInfo: _showPantryStaplesInfoDialog,
                onAddPantry: _showPantryPickerBottomSheet,
              ),
              if (selectedSorted.isNotEmpty) ...[
                const SizedBox(height: 16),
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
              ],
              const SizedBox(height: 20),
              _PromptSuggestionsStrip(
                homeViewModel: widget.homeViewModel,
                onSelect: _onIdeaSelected,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Warm hero text; corner photo is the tab background behind this row.
class _HomeHeroRow extends StatelessWidget {
  const _HomeHeroRow({required this.greetingLine});

  final String greetingLine;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final halo = dark
        ? Colors.black.withValues(alpha: 0.55)
        : Theme.of(context).colorScheme.surface.withValues(alpha: 0.92);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greetingLine 👋',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: 'serif',
            fontWeight: FontWeight.w800,
            fontSize: 28,
            height: 1.1,
            color: onSurface,
            shadows: [
              Shadow(color: halo, blurRadius: 10),
              Shadow(color: halo, blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${AppStrings.letsCookSomethingNice} 💛',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: onSurface,
            shadows: [Shadow(color: halo, blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}

class _HomeSearchField extends StatefulWidget {
  const _HomeSearchField({
    required this.controller,
    required this.onGo,
    required this.coachGetRecipesKey,
  });

  final TextEditingController controller;
  final Future<void> Function() onGo;
  final GlobalKey coachGetRecipesKey;

  @override
  State<_HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<_HomeSearchField>
    with SingleTickerProviderStateMixin {
  static const Duration _borderGlowPeriod = Duration(seconds: 4);

  late final AnimationController _borderGlowCtrl = AnimationController(
    vsync: this,
    duration: _borderGlowPeriod,
  )..repeat();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant _HomeSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    _borderGlowCtrl.dispose();
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.whatDoYouFeelLikeEating,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _borderGlowCtrl,
          builder: (context, _) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            final pulse = sin(_borderGlowCtrl.value * 2 * pi) * 0.5 + 0.5;
            final auraAlpha =
                dark ? (0.12 + pulse * 0.18) : (0.10 + pulse * 0.16);
            return Container(
              key: widget.coachGetRecipesKey,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: SweepGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.82),
                    scheme.tertiary.withValues(alpha: 0.78),
                    scheme.secondary.withValues(alpha: 0.68),
                    scheme.primary.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.38, 0.74, 1.0],
                  transform: GradientRotation(_borderGlowCtrl.value * 2 * pi),
                ),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: auraAlpha),
                    blurRadius: 14 + pulse * 10,
                    spreadRadius: pulse * 0.5,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: dark ? 0.45 : 0.08,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                  if (dark)
                    BoxShadow(
                      color: scheme.outlineVariant.withValues(alpha: 0.15),
                      blurRadius: 0,
                      spreadRadius: 1,
                      offset: Offset.zero,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ColoredBox(
                  color: scheme.surfaceContainerHigh,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            minLines: 1,
                            maxLines: 3,
                            onChanged: (_) => setState(() {}),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                            cursorColor: onSurface,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              hintText: hasText
                                  ? null
                                  : 'e.g. something light, pasta, curry',
                              hintStyle: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(4, 12, 8, 12),
                            ),
                          ),
                        ),
                        Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => widget.onGo(),
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
            );
          },
        ),
      ],
    );
  }
}

typedef _FilterTap = void Function(String phrase);

class _HomeFilterChips extends StatelessWidget {
  const _HomeFilterChips({required this.onSelect});

  final _FilterTap onSelect;

  static const List<({String label, IconData icon, String phrase})> _options = [
    (
      label: 'Quick & Easy',
      icon: Icons.flash_on,
      phrase: 'Quick and easy dinner under 30 minutes',
    ),
    (
      label: 'High Protein',
      icon: Icons.fitness_center,
      phrase: 'High protein healthy meal',
    ),
    (
      label: 'Vegetarian',
      icon: Icons.eco,
      phrase: 'Tasty vegetarian recipe',
    ),
    (
      label: 'Low Calorie',
      icon: Icons.local_fire_department,
      phrase: 'Light low calorie dinner',
    ),
    (
      label: 'Comfort Food',
      icon: Icons.ramen_dining,
      phrase: 'Warm comforting food',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Material(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => onSelect(_options[i].phrase),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _options[i].icon,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _options[i].label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PantryHintBar extends StatelessWidget {
  const _PantryHintBar({
    required this.coachAddPantryKey,
    required this.colorScheme,
    required this.onInfo,
    required this.onAddPantry,
  });

  final Key coachAddPantryKey;
  final ColorScheme colorScheme;
  final VoidCallback onInfo;
  final VoidCallback onAddPantry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lunch_dining, color: colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.3,
                          color: colorScheme.onSurface,
                        ),
                    children: [
                      const TextSpan(text: AppStrings.pantryStaples),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Transform.translate(
                          offset: const Offset(2, -2),
                          child: Tooltip(
                            message: AppStrings.pantryStaplesInfoIconTooltip,
                            child: InkWell(
                              onTap: onInfo,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: coachAddPantryKey,
            onPressed: onAddPantry,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.primary, width: 1.2),
              backgroundColor: colorScheme.surface,
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Pantry Items'),
          ),
        ],
      ),
    );
  }
}

/// Recipe idea cards: image band + text (horizontal list height budget).
const double _kIdeaCardWidth = 200;
const double _kIdeaImageHeight = 108;
const double _kIdeaCardHeight = 214;

class _PromptSuggestionsStrip extends StatelessWidget {
  const _PromptSuggestionsStrip({
    required this.homeViewModel,
    required this.onSelect,
  });

  final HomeViewModel homeViewModel;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: homeViewModel,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        if (homeViewModel.promptSuggestionsLoading) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ideasSectionHeader(context),
              const SizedBox(height: 8),
              SizedBox(
                height: _kIdeaCardHeight,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 10 : 0),
                        child: Shimmer.fromColors(
                          baseColor: scheme.surfaceContainerHighest,
                          highlightColor: Color.lerp(
                                scheme.surfaceContainerHighest,
                                scheme.onSurface,
                                0.12,
                              ) ??
                              scheme.surfaceContainerHigh,
                          period: const Duration(milliseconds: 1500),
                          child: _IdeaCardPlaceholder(colorScheme: scheme),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        }
        final fromApi = homeViewModel.promptSuggestions;
        final items = fromApi.isNotEmpty ? fromApi : _kDemoPromptIdeas;
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ideasSectionHeader(context),
            const SizedBox(height: 8),
            SizedBox(
              height: _kIdeaCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final s = items[index];
                  return _PromptSuggestionTile(
                    text: s.text,
                    subtitle: s.subtitle,
                    timeLabel: '15 min',
                    colorScheme: scheme,
                    onTap: () => onSelect(s.text),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

Row _ideasSectionHeader(BuildContext context) {
  final onSurface = Theme.of(context).colorScheme.onSurface;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Ideas for you',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
      ),
      TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF8F00),
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('See all >'),
      ),
    ],
  );
}

class _IdeaCardPlaceholder extends StatelessWidget {
  const _IdeaCardPlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kIdeaCardWidth,
      height: _kIdeaCardHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _PromptSuggestionTile extends StatelessWidget {
  const _PromptSuggestionTile({
    required this.text,
    this.subtitle,
    this.timeLabel = '15 min',
    required this.colorScheme,
    required this.onTap,
  });

  final String text;
  final String? subtitle;
  final String timeLabel;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = colorScheme;
    return SizedBox(
      width: _kIdeaCardWidth,
      height: _kIdeaCardHeight,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: _kIdeaCardWidth,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.45),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.28
                        : 0.05,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _kIdeaImageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? scheme.surfaceContainerHigh
                            : const Color(0xFFFFE0B2),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: scheme.primary.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onPrimary,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFFFF6F00),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
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
  });

  final dynamic sessionManager;
  final List<String> initialSelected;

  @override
  State<_PantryPickerSheet> createState() => _PantryPickerSheetState();
}

class _PantryPickerSheetState extends State<_PantryPickerSheet> {
  late final TextEditingController _controller;
  late final Set<String> _selected;

  List<String> get _cuisineOptionsForUsualCuisines {
    return AppStrings.cuisineOptions
        .where((c) => c != AppStrings.surpriseMe)
        .toList();
  }

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

  void _toggleUsualCuisine(String cuisine) {
    final current = widget.sessionManager.getUsualCuisines().toSet();
    if (current.contains(cuisine)) {
      current.remove(cuisine);
    } else {
      current.add(cuisine);
    }
    widget.sessionManager.saveUsualCuisinesSync(current.toList());
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

    final colorScheme = Theme.of(context).colorScheme;
    final usualCuisines = widget.sessionManager.getUsualCuisines().toSet();
    final suggestedQuickChips =
        PantryItems.suggestedForCuisines(usualCuisines.toList(), limit: 24);
    final suggestionChipsOnly =
        suggestedQuickChips.where((item) => !_selected.contains(item)).toList();

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
                  Material(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          AppStrings.pantrySuggestionsTitle,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        subtitle: Text(
                          usualCuisines.isEmpty
                              ? AppStrings.suggestionsTapToChooseCuisines
                              : usualCuisines.join(', '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                        maintainState: true,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppStrings.usualCuisinesHeading,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.usualCuisinesPickerHint,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                for (final cuisine
                                    in _cuisineOptionsForUsualCuisines)
                                  CheckboxListTile(
                                    dense: true,
                                    value: usualCuisines.contains(cuisine),
                                    title: Text(cuisine),
                                    onChanged: (_) =>
                                        _toggleUsualCuisine(cuisine),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (suggestionChipsOnly.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                            onTap: () => _toggle(item),
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
    required this.groceryListViewModel,
    required this.isGuest,
    required this.coachFavoritesKey,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final bool isGuest;
  final GlobalKey coachFavoritesKey;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: coachFavoritesKey,
      child: FavoriteRecipesListView(
        homeViewModel: homeViewModel,
        recipeViewModel: recipeViewModel,
        groceryListViewModel: groceryListViewModel,
        isGuest: isGuest,
        onGuestSignUpTap: () => goToSignup(context),
      ),
    );
  }
}
