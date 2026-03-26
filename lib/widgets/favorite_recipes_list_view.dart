import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../view_models/home_view_model.dart';
import 'guest_signup_prompt.dart';

/// Favorites list with swipe-left to remove (save-favorites with isFavorite: false).
class FavoriteRecipesListView extends StatelessWidget {
  const FavoriteRecipesListView({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    this.isGuest = false,
    this.onGuestSignUpTap,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final bool isGuest;
  final VoidCallback? onGuestSignUpTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: homeViewModel,
      builder: (_, __) {
        if (isGuest) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No Favorites Yet',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign up to create and access your favorite recipes.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onGuestSignUpTap ?? () => goToSignup(context),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ),
          );
        }
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
                onTap: () => _openFavoriteRecipe(
                  context,
                  homeViewModel: homeViewModel,
                  listRecipe: recipe,
                  recipeViewModel: recipeViewModel,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _openFavoriteRecipe(
  BuildContext context, {
  required HomeViewModel homeViewModel,
  required Recipe listRecipe,
  required dynamic recipeViewModel,
}) async {
  if (listRecipe.recipeId.isEmpty) {
    if (!context.mounted) return;
    context.push(
      '/show-recipe',
      extra: {
        'recipe': listRecipe,
        'recipeViewModel': recipeViewModel,
      },
    );
    return;
  }

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
    final full =
        await homeViewModel.fetchFavoriteRecipeDetail(listRecipe.recipeId);
    final toShow = full.copyWith(isFavorite: true);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    context.push(
      '/show-recipe',
      extra: {
        'recipe': toShow,
        'recipeViewModel': recipeViewModel,
      },
    );
  } on ApiException catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load recipe')),
      );
    }
  }
}
