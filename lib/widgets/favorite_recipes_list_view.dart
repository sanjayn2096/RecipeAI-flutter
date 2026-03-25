import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../view_models/home_view_model.dart';

/// Favorites list with swipe-left to remove (save-favorites with isFavorite: false).
class FavoriteRecipesListView extends StatelessWidget {
  const FavoriteRecipesListView({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: homeViewModel,
      builder: (_, __) {
        if (homeViewModel.favoritesLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading favorites…'),
              ],
            ),
          );
        }
        final favorites = homeViewModel.apiFavorites;
        if (favorites.isEmpty) {
          return const Center(child: Text('No favorites yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: favorites.length,
          itemBuilder: (_, i) {
            final recipe = favorites[i];
            final dismissKey = recipe.recipeId.isNotEmpty
                ? 'favorite_${recipe.recipeId}'
                : 'favorite_h_${Object.hash(recipe.recipeName, recipe.cuisine, recipe.cookingTime, i)}';
            return Dismissible(
              key: ValueKey(dismissKey),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Remove from favorites?'),
                    content: Text(
                      'Remove "${recipe.recipeName}" from your favorites?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                );
                return confirmed ?? false;
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: Theme.of(context).colorScheme.error,
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onError,
                  size: 28,
                ),
              ),
              onDismissed: (_) {
                homeViewModel.removeFavoriteWithSwipe(recipe).then((ok) {
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not remove from favorites'),
                      ),
                    );
                  }
                });
              },
              child: ListTile(
                title: Text(recipe.recipeName),
                subtitle: Text(recipe.cuisine),
                onTap: () {
                  context.push(
                    '/show-recipe',
                    extra: {
                      'recipe': recipe,
                      'recipeViewModel': recipeViewModel,
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
