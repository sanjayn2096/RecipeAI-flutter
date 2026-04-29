import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../view_models/home_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import 'cartoon_outlined_card.dart';
import 'recipe_list_row.dart';
import 'guest_signup_prompt.dart';

/// Saved list with swipe-left to remove (POST /save-favorites with isSaved: false).
class FavoriteRecipesListView extends StatefulWidget {
  const FavoriteRecipesListView({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    this.isGuest = false,
    this.onGuestSignUpTap,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final bool isGuest;
  final VoidCallback? onGuestSignUpTap;

  @override
  State<FavoriteRecipesListView> createState() =>
      _FavoriteRecipesListViewState();
}

class _FavoriteRecipesListViewState extends State<FavoriteRecipesListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        if (widget.isGuest) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nothing saved yet',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign up to save recipes to your account and open them anytime.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed:
                        widget.onGuestSignUpTap ?? () => goToSignup(context),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ),
          );
        }
        if (widget.homeViewModel.savedLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading saved recipes…'),
              ],
            ),
          );
        }
        final saved = widget.homeViewModel.apiSaved;
        if (saved.isEmpty) {
          return const Center(child: Text('No saved recipes yet'));
        }
        final filtered = saved
            .where((r) => r.matchesSearchQuery(_searchController.text))
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search saved',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No recipes match your search',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final recipe = filtered[i];
                        final dismissKey = recipe.recipeId.isNotEmpty
                            ? 'saved_${recipe.recipeId}'
                            : 'saved_h_${Object.hash(recipe.recipeName, recipe.cuisine, recipe.cookingTime, i)}';
                        return Dismissible(
                          key: ValueKey(dismissKey),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Remove from saved?'),
                                content: Text(
                                  'Remove "${recipe.recipeName}" from your saved list?',
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
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onError,
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
                            widget.homeViewModel
                                .removeSavedWithSwipe(recipe)
                                .then((ok) {
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Could not remove from saved'),
                                  ),
                                );
                              }
                            });
                          },
                          child: CartoonOutlinedCard(
                            child: RecipeListRow(
                              recipe: recipe,
                              trailingActions: const [],
                              onTap: () => _openSavedRecipe(
                                context,
                                homeViewModel: widget.homeViewModel,
                                listRecipe: recipe,
                                recipeViewModel: widget.recipeViewModel,
                                groceryListViewModel:
                                    widget.groceryListViewModel,
                              ),
                            ),
                          ),
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

Future<void> _openSavedRecipe(
  BuildContext context, {
  required HomeViewModel homeViewModel,
  required Recipe listRecipe,
  required dynamic recipeViewModel,
  required GroceryListViewModel groceryListViewModel,
}) async {
  if (listRecipe.recipeId.isEmpty) {
    if (!context.mounted) return;
    context.push(
      '/show-recipe',
      extra: {
        'recipe': listRecipe,
        'recipeViewModel': recipeViewModel,
        'groceryListViewModel': groceryListViewModel,
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
        await homeViewModel.fetchSavedRecipeDetail(listRecipe.recipeId);
    final toShow = full.copyWith(isSaved: true);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    context.push(
      '/show-recipe',
      extra: {
        'recipe': toShow,
        'recipeViewModel': recipeViewModel,
        'groceryListViewModel': groceryListViewModel,
      },
    );
  } on ApiException catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
