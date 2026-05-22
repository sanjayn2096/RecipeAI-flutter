import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/monetization_navigation.dart';
import '../core/telemetry/app_telemetry.dart';
import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../view_models/home_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/subscription_view_model.dart';
import '../widgets/cartoon_outlined_card.dart';
import '../widgets/recipe_list_row.dart';

/// Premium feed of newest community recipes.
class LatestRecipesScreen extends StatefulWidget {
  const LatestRecipesScreen({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.subscriptionViewModel,
    required this.appTelemetry,
    required this.onBack,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;
  final VoidCallback onBack;

  @override
  State<LatestRecipesScreen> createState() => _LatestRecipesScreenState();
}

class _LatestRecipesScreenState extends State<LatestRecipesScreen> {
  Future<List<Recipe>>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.subscriptionViewModel.isPremium) {
      _future = widget.homeViewModel.loadLatestRecipes();
    }
    widget.subscriptionViewModel.addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    if (widget.subscriptionViewModel.isPremium && _future == null) {
      setState(() {
        _future = widget.homeViewModel.loadLatestRecipes();
      });
    }
  }

  @override
  void dispose() {
    widget.subscriptionViewModel.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  Future<void> _openRecipe(Recipe listRecipe) async {
    if (listRecipe.recipeId.isEmpty) return;
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading recipe…'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final full = await widget.homeViewModel
          .fetchSavedRecipeDetail(listRecipe.recipeId);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.push(
        '/show-recipe',
        extra: {
          'recipe': full,
          'recipeViewModel': widget.recipeViewModel,
          'groceryListViewModel': widget.groceryListViewModel,
        },
      );
    } on ApiException catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Widget _lockedBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Latest recipes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Premium members get early access to the newest recipes as they’re added.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => openPremiumPaywall(
                context,
                source: 'latest_recipes',
                appTelemetry: widget.appTelemetry,
              ),
              child: const Text('Unlock with Premium'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest recipes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        actions: [
          if (widget.subscriptionViewModel.isPremium)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _future = widget.homeViewModel.loadLatestRecipes();
                });
              },
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.subscriptionViewModel,
        builder: (context, _) {
          if (!widget.subscriptionViewModel.isPremium) {
            return _lockedBody(context);
          }
          return FutureBuilder<List<Recipe>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading latest recipes…'),
                    ],
                  ),
                );
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final list = snap.data ?? const <Recipe>[];
              if (list.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No latest recipes yet. Check back soon.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final r = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CartoonOutlinedCard(
                      child: RecipeListRow(
                        recipe: r,
                        metaExtra: 'New',
                        trailingActions: [
                          Padding(
                            padding: const EdgeInsets.only(right: 4, top: 4),
                            child: Icon(
                              Icons.new_releases_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                        onTap: () => _openRecipe(r),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
