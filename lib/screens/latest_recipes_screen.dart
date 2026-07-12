import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/telemetry/app_telemetry.dart';
import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../view_models/home_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/subscription_view_model.dart';
import '../widgets/cartoon_outlined_card.dart';
import '../widgets/recipe_list_row.dart';

/// Feed of newest community recipes (public discovery).
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
  late Future<List<Recipe>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.homeViewModel.loadLatestRecipes();
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
      body: FutureBuilder<List<Recipe>>(
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CartoonOutlinedCard(
                  child: RecipeListRow(
                    recipe: r,
                    trailingActions: const [
                      Padding(
                        padding: EdgeInsets.only(right: 4, top: 4),
                        child: Icon(Icons.new_releases_outlined),
                      ),
                    ],
                    onTap: () => _openRecipe(r),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
