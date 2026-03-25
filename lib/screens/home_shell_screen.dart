import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/pantry_items.dart';
import '../data/models/user_data.dart';
import '../view_models/home_view_model.dart';
import '../widgets/favorite_recipes_list_view.dart';
import 'recipe_flow_screen.dart';

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
  final dynamic recipeViewModel;
  final dynamic sessionManager;

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.homeViewModel.addListener(_onHomeUpdate);
    widget.homeViewModel.loadUserDetails();
  }

  @override
  void dispose() {
    widget.homeViewModel.removeListener(_onHomeUpdate);
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
    setState(() => _currentIndex = index);
    if (index == 1) {
      // Create Recipes uses mood/diet/cuisine only — ignore Home "Generate from text" session value.
      widget.sessionManager.savePreferenceSync('customPreference', '');
    }
    if (index == 2) {
      widget.homeViewModel.loadFavoritesFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        final userData = widget.homeViewModel.userData;
        return Scaffold(
          appBar: _currentIndex == 1
              ? null
              : AppBar(
                  title: Text(_appBarTitle),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.person),
                      onPressed: () => context.push('/profile'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
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
                userData: userData,
              ),
              RecipeFlowScreen(
                userData: userData,
                recipeViewModel: widget.recipeViewModel,
                sessionManager: widget.sessionManager,
                embedInTab: true,
              ),
              _FavoritesTabBody(
                homeViewModel: widget.homeViewModel,
                recipeViewModel: widget.recipeViewModel,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
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
    required this.userData,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final dynamic sessionManager;
  final UserData? userData;

  @override
  State<_HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<_HomeTabBody> {
  late final TextEditingController _customPreferenceController;

  /// Prefer fetch-user-details name, then stored get_user_profile first name.
  String? _greetingName() {
    final fromUser = widget.userData?.firstName.trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    final fromProfile = widget.homeViewModel.sessionProfile.firstName.trim();
    if (fromProfile.isNotEmpty) return fromProfile;
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
                onPressed: () {
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
                  context.push('/recipe-flow', extra: {
                    'userData': widget.userData,
                    if (freeText.isNotEmpty) 'initialPrompt': freeText,
                  });
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Find Recipes'),
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.pantryStaples,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              // Variable-width pills, fixed height; wrap to next row when a row doesn’t fit.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final item in PantryItems.common)
                    _PantryPill(
                      label: item,
                      selected: selected.contains(item),
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
              ? const Color(0xFF2E7D32)
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
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;

  @override
  Widget build(BuildContext context) {
    return FavoriteRecipesListView(
      homeViewModel: homeViewModel,
      recipeViewModel: recipeViewModel,
    );
  }
}
