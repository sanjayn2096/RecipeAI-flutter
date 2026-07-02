import 'dart:async' show unawaited;
import 'dart:math' show max, min, pi, sin;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:recipe_ai/l10n/app_localizations.dart';

import '../core/l10n_context.dart';
import '../core/l10n_extensions.dart';
import '../core/recipe_generation_entry_point.dart';
import '../data/models/recipe.dart';
import '../data/models/session_profile.dart';
import '../data/models/user_data.dart';
import '../tutorial/coach_tour.dart';
import '../core/pantry_items.dart';
import '../view_models/home_view_model.dart';
import '../view_models/recipe_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/brand_outlined_surface.dart';
import '../widgets/favorite_recipes_list_view.dart';
import '../widgets/sous_chef_brand.dart';
import '../widgets/sous_chef_menu_button.dart';
import '../widgets/guest_signup_prompt.dart';
import '../widgets/recipe_image_box.dart';
import '../widgets/bottom_ad_banner.dart';
import '../widgets/daily_credits_indicator.dart';
import '../core/monetization_navigation.dart';
import '../core/telemetry/app_telemetry.dart';
import '../onboarding/onboarding_session_extension.dart';
import '../services/session_manager.dart';
import '../view_models/subscription_view_model.dart';
import 'grocery_list_screen.dart';
import 'import/import_hub_screen.dart';
import 'recipe_flow_screen.dart';

/// Matches selected pantry pills and sheet highlights.
const Color _kPantrySelectedGreen = Color(0xFF2E7D32);

/// App bar: shared surface, [SousChefMenuButton], mark + "Sous Chef", profile initial + menu.
class _SousHomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SousHomeAppBar({
    required this.onOpenMenu,
    required this.firstNameLetter,
    required this.isGuest,
    required this.onSignOut,
    required this.sessionManager,
    required this.subscriptionViewModel,
    required this.appTelemetry,
  });

  final VoidCallback onOpenMenu;
  final String firstNameLetter;
  final bool isGuest;
  final VoidCallback onSignOut;
  final SessionManager sessionManager;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;

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
          tooltip: context.l10n.appMenuTooltip,
          onPressed: onOpenMenu,
        ),
      ),
      leadingWidth: 60,
      actions: [
        DailyCreditsIndicator(
          sessionManager: sessionManager,
          subscriptionViewModel: subscriptionViewModel,
          appTelemetry: appTelemetry,
        ),
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
                  BrandOutlinedAvatar(label: firstNameLetter),
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

/// Main shell after login: bottom nav — Home, Create Recipes, Grocery, Import, Saved.
class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({
    super.key,
    required this.homeViewModel,
    required this.loginViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.subscriptionViewModel,
    required this.appTelemetry,
    required this.sessionManager,
  });

  final HomeViewModel homeViewModel;
  final dynamic loginViewModel;
  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final SubscriptionViewModel subscriptionViewModel;
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
  final GlobalKey _coachImportLinksKey = GlobalKey();
  final GlobalKey _coachImportPasteKey = GlobalKey();
  final GlobalKey _coachImportScanKey = GlobalKey();
  late CoachTourController _coachTour;
  late CoachTourController _importHubCoachTour;
  bool _coachToursReady = false;

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
    if (index == 4 && !widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadSavedFromApi(
        showLoading: false,
        ignoreCache: true,
      );
    }
  }

  void _startCoachTour() {
    if (_coachTour.isActive || _importHubCoachTour.isActive) return;
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _coachTour.start();
    });
  }

  /// First visit to Import tab — spotlight the three tiles (once per install).
  void _scheduleImportHubCoachIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeStartImportHubCoachTour();
    });
  }

  void _maybeStartImportHubCoachTour() {
    if (_currentIndex != 3) return;
    if (widget.sessionManager.getImportHubCoachSeenSync()) return;
    if (_coachTour.isActive || _importHubCoachTour.isActive) return;
    _importHubCoachTour.start();
  }

  void _finishImportHubCoachTourSeen() {
    widget.sessionManager.setImportHubCoachSeenSync(true);
    _importHubCoachTour.finish();
  }

  void _onImportCoachNext() {
    if (!_importHubCoachTour.isActive) return;
    if (_importHubCoachTour.isLastStep) {
      _finishImportHubCoachTourSeen();
      return;
    }
    final nextIdx = _importHubCoachTour.currentIndex + 1;
    final nextStep = _importHubCoachTour.steps[nextIdx];
    if (nextStep.tabIndex != null && nextStep.tabIndex != _currentIndex) {
      setState(() {
        _currentIndex = nextStep.tabIndex!;
        _applyTabSideEffects(_currentIndex);
      });
    }
    _importHubCoachTour.next();
  }

  void _onImportCoachBack() {
    if (!_importHubCoachTour.isActive || _importHubCoachTour.currentIndex <= 0) {
      return;
    }
    final prevIdx = _importHubCoachTour.currentIndex - 1;
    final prevStep = _importHubCoachTour.steps[prevIdx];
    if (prevStep.tabIndex != null && prevStep.tabIndex != _currentIndex) {
      setState(() {
        _currentIndex = prevStep.tabIndex!;
        _applyTabSideEffects(_currentIndex);
      });
    }
    _importHubCoachTour.previous();
  }

  void _onImportCoachSkip() => _finishImportHubCoachTourSeen();

  void _onCoachNext() {
    if (!_coachTour.isActive) return;
    if (_coachTour.isLastStep) {
      _finishMainCoachTour();
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
    _markImportHubCoachSeenAfterMainTour();
  }

  void _finishMainCoachTour() {
    _coachTour.finish();
    _markImportHubCoachSeenAfterMainTour();
  }

  void _markImportHubCoachSeenAfterMainTour() {
    widget.sessionManager.setImportHubCoachSeenSync(true);
  }

  void _ensureCoachTours(BuildContext context) {
    if (_coachToursReady) return;
    final l10n = context.l10n;
    _coachTour = CoachTourController(
      steps: [
        CoachTourStep(
          targetKey: _coachNavKey,
          title: l10n.coachStepNavTitle,
          body: l10n.coachStepNavBody,
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: _coachGetRecipesKey,
          title: l10n.coachStepGetRecipesTitle,
          body: l10n.coachStepGetRecipesBody,
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: _coachAddPantryKey,
          title: l10n.coachStepAddPantryTitle,
          body: l10n.coachStepAddPantryBody,
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: _coachImportLinksKey,
          title: l10n.coachStepImportLinksTitle,
          body: l10n.coachStepImportLinksBody,
          tabIndex: 3,
        ),
        CoachTourStep(
          targetKey: _coachImportPasteKey,
          title: l10n.coachStepImportPasteTitle,
          body: l10n.coachStepImportPasteBody,
          tabIndex: 3,
        ),
        CoachTourStep(
          targetKey: _coachImportScanKey,
          title: l10n.coachStepImportScanTitle,
          body: l10n.coachStepImportScanBody,
          tabIndex: 3,
        ),
        CoachTourStep(
          targetKey: _coachFavoritesKey,
          title: l10n.coachStepFavoritesTitle,
          body: l10n.coachStepFavoritesBody,
          tabIndex: 4,
        ),
      ],
    );
    _importHubCoachTour = CoachTourController(
      steps: [
        CoachTourStep(
          targetKey: _coachImportLinksKey,
          title: l10n.coachStepImportLinksTitle,
          body: l10n.coachStepImportLinksBody,
          tabIndex: 3,
        ),
        CoachTourStep(
          targetKey: _coachImportPasteKey,
          title: l10n.coachStepImportPasteTitle,
          body: l10n.coachStepImportPasteBody,
          tabIndex: 3,
        ),
        CoachTourStep(
          targetKey: _coachImportScanKey,
          title: l10n.coachStepImportScanTitle,
          body: l10n.coachStepImportScanBody,
          tabIndex: 3,
        ),
      ],
    );
    _coachToursReady = true;
  }

  @override
  void initState() {
    super.initState();
    widget.homeViewModel.addListener(_onHomeUpdate);
    widget.homeViewModel.loadUserDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureCoachTours(context);
  }

  @override
  void dispose() {
    widget.homeViewModel.removeListener(_onHomeUpdate);
    if (_coachToursReady) {
      _coachTour.dispose();
      _importHubCoachTour.dispose();
    }
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
    if (_importHubCoachTour.isActive && index != 3 && index != _currentIndex) {
      _importHubCoachTour.finish();
    }
    final wasCreate = _currentIndex == 1;
    if (wasCreate && index != 1) {
      final err = widget.recipeViewModel.fetchError;
      if (err != null && err.isNotEmpty) {
        widget.recipeViewModel.clearRecipeGenerationState();
        setState(() {
          _embeddedRecipeFlowKey++;
          _currentIndex = index;
        });
        if (index == 4 && !widget.sessionManager.isGuestMode()) {
          widget.homeViewModel.loadSavedFromApi(
            showLoading: false,
            ignoreCache: true,
          );
        }
        if (index == 3) {
          _scheduleImportHubCoachIfNeeded();
        }
        return;
      }
    }
    setState(() => _currentIndex = index);
    if (index == 1) {
      // Create Recipes uses mood/diet/cuisine only — ignore Home "Generate from text" session value.
      widget.sessionManager.savePreferenceSync('customPreference', '');
    }
    if (index == 4 && !widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadSavedFromApi(
        showLoading: false,
        ignoreCache: true,
      );
    }
    if (index == 3) {
      _scheduleImportHubCoachIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureCoachTours(context);
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        final l10n = context.l10n;
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
                              l10n.appName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.tutorialDrawerSubtitle,
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
                        title: Text(l10n.howToUse),
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
                        title: Text(l10n.showMeAround),
                        onTap: () {
                          Navigator.of(context).pop();
                          _startCoachTour();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.trending_up),
                        title: const Text('See trending recipes'),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/trending');
                        },
                      ),
                      ListTile(
                        leading: Icon(
                          widget.subscriptionViewModel.isPremium
                              ? Icons.new_releases
                              : Icons.new_releases_outlined,
                        ),
                        title: const Text('Latest recipes'),
                        trailing: widget.subscriptionViewModel.isPremium
                            ? null
                            : const Icon(Icons.lock_outline, size: 18),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/latest-recipes');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.workspace_premium_outlined),
                        title: Text(
                          widget.subscriptionViewModel.isPremium
                              ? 'Premium active'
                              : 'Sous Chef Premium',
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          openPremiumPaywall(
                            context,
                            source: 'drawer',
                            appTelemetry: widget.appTelemetry,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: Text(l10n.mealPlanDrawer),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/meal-plan');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.shopping_cart_outlined),
                        title: Text(l10n.groceryListDrawer),
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
                      sessionManager: widget.sessionManager,
                      subscriptionViewModel: widget.subscriptionViewModel,
                      appTelemetry: widget.appTelemetry,
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
                                tooltip: l10n.appMenuTooltip,
                                onPressed: _openAppDrawer,
                              ),
                            ),
                          ),
                          leadingWidth: 56,
                          title: Text(_appBarTitle(l10n)),
                        ),
              body: _buildActiveTab(userData: userData, isGuest: isGuest),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BottomAdBanner(
                    subscriptionViewModel: widget.subscriptionViewModel,
                    appTelemetry: widget.appTelemetry,
                  ),
                  KeyedSubtree(
                    key: _coachNavKey,
                    child: NavigationBar(
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _onTabTapped,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.restaurant_outlined),
                          selectedIcon: Icon(Icons.restaurant),
                          label: 'Create',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.shopping_cart_outlined),
                          selectedIcon: Icon(Icons.shopping_cart),
                          label: 'Grocery',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.download_for_offline_outlined),
                          selectedIcon: Icon(Icons.download_for_offline),
                          label: 'Import',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bookmark_outline),
                          selectedIcon: Icon(Icons.bookmark),
                          label: 'Saved',
                        ),
                      ],
                    ),
                  ),
                ],
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
            ListenableBuilder(
              listenable: _importHubCoachTour,
              builder: (_, __) {
                if (!_importHubCoachTour.isActive) {
                  return const SizedBox.shrink();
                }
                return CoachMarkOverlay(
                  controller: _importHubCoachTour,
                  onNext: _onImportCoachNext,
                  onBack: _onImportCoachBack,
                  onSkip: _onImportCoachSkip,
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Only the selected bottom-nav tab is built (unlike [IndexedStack], which kept all five).
  Widget _buildActiveTab({
    required UserData? userData,
    required bool isGuest,
  }) {
    switch (_currentIndex) {
      case 0:
        return _HomeTabBody(
          homeViewModel: widget.homeViewModel,
          recipeViewModel: widget.recipeViewModel,
          sessionManager: widget.sessionManager,
          subscriptionViewModel: widget.subscriptionViewModel,
          appTelemetry: widget.appTelemetry,
          coachGetRecipesKey: _coachGetRecipesKey,
          coachAddPantryKey: _coachAddPantryKey,
        );
      case 1:
        return RecipeFlowScreen(
          key: ValueKey<int>(_embeddedRecipeFlowKey),
          userData: userData,
          recipeViewModel: widget.recipeViewModel,
          groceryListViewModel: widget.groceryListViewModel,
          sessionManager: widget.sessionManager,
          embedInTab: true,
          onOpenAppMenu: _openAppDrawer,
        );
      case 2:
        return GroceryListScreen(
          groceryListViewModel: widget.groceryListViewModel,
          appTelemetry: widget.appTelemetry,
          embedInShell: true,
        );
      case 3:
        return ImportHubScreen(
          sessionManager: widget.sessionManager,
          subscriptionViewModel: widget.subscriptionViewModel,
          appTelemetry: widget.appTelemetry,
          recipeViewModel: widget.recipeViewModel,
          groceryListViewModel: widget.groceryListViewModel,
          coachImportLinksKey: _coachImportLinksKey,
          coachImportPasteKey: _coachImportPasteKey,
          coachImportScanKey: _coachImportScanKey,
        );
      case 4:
        return _FavoritesTabBody(
          homeViewModel: widget.homeViewModel,
          recipeViewModel: widget.recipeViewModel,
          groceryListViewModel: widget.groceryListViewModel,
          isGuest: isGuest,
          coachFavoritesKey: _coachFavoritesKey,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _appBarTitle(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return l10n.appName;
      case 2:
        return l10n.groceryListTitle;
      case 3:
        return l10n.importRecipeTabTitle;
      case 4:
        return 'Saved';
      default:
        return l10n.appName;
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
    required this.subscriptionViewModel,
    required this.appTelemetry,
    required this.coachGetRecipesKey,
    required this.coachAddPantryKey,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final dynamic sessionManager;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;
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

  void _openPantryScan() {
    if (!widget.subscriptionViewModel.isPremium) {
      openPremiumPaywall(
        context,
        source: 'pantry_scan',
        appTelemetry: widget.appTelemetry,
      );
      return;
    }
    context.push('/pantry-scan').then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showPantryStaplesInfoDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pantryStaplesDialogTitle),
        content: Text(l10n.pantryStaplesInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFirstPromptHint());
  }

  void _maybeShowFirstPromptHint() {
    if (!mounted) return;
    if (widget.sessionManager.getFirstPromptHintSeenSync()) return;
    widget.sessionManager.setFirstPromptHintSeenSync(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.onboardingFirstPromptHint)),
    );
    setState(() => _highlightFirstPrompt = true);
  }

  bool _highlightFirstPrompt = false;

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
    unawaited(_startRecipeFlow(promptOverride: phrase));
  }

  bool _canStartHomeRecipeFlow(String freeText, bool hasIngredients) {
    if (freeText.isNotEmpty || hasIngredients) return true;
    final sm = widget.sessionManager as SessionManager;
    if (sm.isGuestMode()) return false;
    // Signed-in users can generate from saved lifestyle prefs / feeling-lucky defaults.
    return true;
  }

  void _showHomeRecipeInputRequired() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a little context'),
        content: const Text(
          'Describe what you feel like eating, pick a quick filter above, '
          'or add pantry items — then tap the arrow to generate recipes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecipeFlow({String? promptOverride}) async {
    try {
      final freeText =
          (promptOverride ?? _customPreferenceController.text).trim();
      final hasIngredients = widget.sessionManager.getIngredients().isNotEmpty;
      if (!_canStartHomeRecipeFlow(freeText, hasIngredients)) {
        _showHomeRecipeInputRequired();
        return;
      }
      if (widget.sessionManager.isGuestMode() &&
          !widget.subscriptionViewModel.isPremium) {
        final exceeded =
            await widget.sessionManager.isGuestRecipeQuotaExceededForToday();
        if (!mounted) return;
        if (exceeded) {
          final action = await showGuestRecipeLimitReachedDialog(
            context,
            appTelemetry: widget.appTelemetry,
          );
          if (!mounted) return;
          if (action == GuestLimitAction.signUp) {
            goToSignup(context);
          } else if (action == GuestLimitAction.premium) {
            openPremiumPaywall(
              context,
              source: 'guest_quota',
              appTelemetry: widget.appTelemetry,
            );
          }
          return;
        }
      }
      if (!widget.sessionManager.isGuestMode() &&
          !widget.subscriptionViewModel.isPremium) {
        final sm = widget.sessionManager as SessionManager;
        final exceeded = await sm.isSignedInFreeRecipeQuotaExceededForToday(
          isPremium: false,
        );
        if (!mounted) return;
        if (exceeded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.freeTierQuotaMessage)),
          );
          openPremiumPaywall(
            context,
            source: 'free_quota',
            appTelemetry: widget.appTelemetry,
          );
          return;
        }
      }
      if (!mounted) return;
      context.push('/recipe-flow', extra: {
        'generationEntryPoint': RecipeGenerationEntryPoint.home.name,
        if (freeText.isNotEmpty) 'initialPrompt': freeText,
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[HomeTab] _startRecipeFlow failed: $e\n$st');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start recipe generation: $e')),
      );
    }
  }

  Future<void> _onGetRecipesPressed() => _startRecipeFlow();

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
              const SizedBox(height: 12),
              _HomeSearchField(
                controller: _customPreferenceController,
                onGo: _onGetRecipesPressed,
                coachGetRecipesKey: widget.coachGetRecipesKey,
                highlightFirstPrompt: _highlightFirstPrompt,
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
                onScanPantry: _openPantryScan,
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
              ListenableBuilder(
                listenable: widget.homeViewModel,
                builder: (context, _) {
                  final ideas = widget.homeViewModel.dailyIdeas;
                  if (ideas.length != 5) return const SizedBox.shrink();
                  return Column(
                    children: [
                      _DailyIdeasStrip(
                        recipes: ideas,
                        onRecipeTap: (recipe) {
                          context.push('/show-recipe', extra: {'recipe': recipe});
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
              _MealPlannerPromoCard(
                onTap: () => context.push('/meal-plan'),
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
          '$greetingLine',
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
          context.l10n.letsCookSomethingNice,
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
    this.highlightFirstPrompt = false,
  });

  final TextEditingController controller;
  final Future<void> Function() onGo;
  final GlobalKey coachGetRecipesKey;
  final bool highlightFirstPrompt;

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
    if (widget.highlightFirstPrompt && !oldWidget.highlightFirstPrompt) {
      _borderGlowCtrl
        ..reset()
        ..repeat();
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
          context.l10n.whatDoYouFeelLikeEating,
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
            final boost = widget.highlightFirstPrompt ? 0.22 : 0.0;
            final auraAlpha =
                dark
                    ? (0.12 + pulse * 0.18 + boost)
                    : (0.10 + pulse * 0.16 + boost);
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
                  color: scheme.surface,
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
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) => unawaited(widget.onGo()),
                            onChanged: (_) => setState(() {}),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                            cursorColor: onSurface,
                            decoration: InputDecoration(
                              filled: false,
                              isDense: true,
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              hintText: hasText
                                  ? null
                                  : 'Quick Weeknight Meal, High Protein meal..?',
                              hintStyle: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                              ),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(4, 12, 8, 12),
                            ),
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Get recipes',
                          style: IconButton.styleFrom(
                            fixedSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => unawaited(widget.onGo()),
                          icon: const Icon(Icons.arrow_forward),
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
      label: 'Busy night',
      icon: Icons.flash_on,
      phrase: 'Busy weeknight — dinner on the table in under 30 minutes, kid-friendly',
    ),
    (
      label: 'Meal prep',
      icon: Icons.calendar_month,
      phrase: 'Meal prep for the week — reheat well, balanced lunches',
    ),
    (
      label: 'Health goals',
      icon: Icons.fitness_center,
      phrase: 'Hitting health goals — high protein, lighter dinner',
    ),
    (
      label: 'Vegetarian',
      icon: Icons.eco,
      phrase: 'Tasty vegetarian dinner, not too heavy',
    ),
    (
      label: 'Comfort',
      icon: Icons.ramen_dining,
      phrase: 'Cozy comfort food after a long day',
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
            BrandOutlinedChip(
              label: _options[i].label,
              icon: _options[i].icon,
              onTap: () => onSelect(_options[i].phrase),
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
    required this.onScanPantry,
  });

  final Key coachAddPantryKey;
  final ColorScheme colorScheme;
  final VoidCallback onInfo;
  final VoidCallback onAddPantry;
  final VoidCallback onScanPantry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                      TextSpan(text: l10n.pantryStaples),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Transform.translate(
                          offset: const Offset(2, -2),
                          child: Tooltip(
                            message: l10n.pantryStaplesInfoIconTooltip,
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
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onScanPantry,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.8),
              ),
              backgroundColor: colorScheme.surface,
            ),
            icon: const Icon(Icons.photo_camera_outlined, size: 20),
            label: Text(l10n.groceryPantryScanScanFromPhoto),
          ),
        ],
      ),
    );
  }
}

/// Horizontal carousel of preloaded daily recipe ideas (backend batch).
class _DailyIdeasStrip extends StatelessWidget {
  const _DailyIdeasStrip({
    required this.recipes,
    required this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final void Function(Recipe recipe) onRecipeTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ideas for you',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return _DailyIdeaCard(
                recipe: recipe,
                colorScheme: scheme,
                onTap: () => onRecipeTap(recipe),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DailyIdeaCard extends StatelessWidget {
  const _DailyIdeaCard({
    required this.recipe,
    required this.colorScheme,
    required this.onTap,
  });

  final Recipe recipe;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecipeImageBox(
                imageUrl: recipe.image,
                height: 96,
                width: 140,
                borderRadius: BorderRadius.zero,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Text(
                    recipe.recipeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home promo for the AI meal planner.
class _MealPlannerPromoCard extends StatelessWidget {
  const _MealPlannerPromoCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 36,
                color: scheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mealPlanHomePrompt,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: onTap,
                      child: Text(l10n.mealPlanHomeCta),
                    ),
                  ],
                ),
              ),
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
  });

  final dynamic sessionManager;
  final List<String> initialSelected;

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

  void _toggleUsualCuisine(String cuisineKey) {
    final current = widget.sessionManager.getUsualCuisines().toSet();
    if (current.contains(cuisineKey)) {
      current.remove(cuisineKey);
    } else {
      current.add(cuisineKey);
    }
    widget.sessionManager.saveUsualCuisinesSync(current.toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preferredCuisineKeys = l10n.preferredCuisineOptionKeys;
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
                          l10n.pantrySuggestionsTitle,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        subtitle: Text(
                          usualCuisines.isEmpty
                              ? l10n.suggestionsTapToChooseCuisines
                              : usualCuisines
                                  .map(l10n.cuisineLabel)
                                  .join(', '),
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
                                  l10n.usualCuisinesHeading,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.usualCuisinesPickerHint,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                for (final cuisineKey in preferredCuisineKeys)
                                  CheckboxListTile(
                                    dense: true,
                                    value: usualCuisines.contains(cuisineKey),
                                    title: Text(l10n.cuisineLabel(cuisineKey)),
                                    onChanged: (_) =>
                                        _toggleUsualCuisine(cuisineKey),
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
