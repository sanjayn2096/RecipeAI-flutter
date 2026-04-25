import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../view_models/home_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/cartoon_outlined_card.dart';

/// Most-favorited recipes (public [favoriteCount] from the server).
class TrendingRecipesScreen extends StatefulWidget {
  const TrendingRecipesScreen({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.onBack,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final VoidCallback onBack;

  @override
  State<TrendingRecipesScreen> createState() => _TrendingRecipesScreenState();
}

class _TrendingRecipesScreenState extends State<TrendingRecipesScreen> {
  late Future<List<Recipe>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.homeViewModel.loadTrendingRecipes();
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
        title: const Text('Trending'),
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
                _future = widget.homeViewModel.loadTrendingRecipes();
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
                  Text('Loading trending recipes…'),
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
                  'No trending recipes yet. Be the first to favorite a recipe you like.',
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    title: Text(r.recipeName),
                    subtitle: Text('${r.cuisine} · ${r.favoriteCount} favorites'),
                    leading: const Icon(Icons.trending_up, color: Colors.orange),
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
