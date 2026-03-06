import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/recipe.dart';
import '../view_models/home_view_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.onBack,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final VoidCallback onBack;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    widget.homeViewModel.loadUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        final favorites = widget.homeViewModel.userData?.favoriteRecipes ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text("User's Favorites"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: favorites.isEmpty
              ? const Center(child: Text('No favorites yet'))
              : ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (_, i) {
                    final recipe = favorites[i];
                    return ListTile(
                      title: Text(recipe.recipeName),
                      subtitle: Text(recipe.cuisine),
                      onTap: () {
                        context.push(
                          '/show-recipe',
                          extra: {
                            'recipe': recipe,
                            'recipeViewModel': widget.recipeViewModel,
                          },
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
