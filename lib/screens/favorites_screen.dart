import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../view_models/home_view_model.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/favorite_recipes_list_view.dart';
import '../widgets/guest_signup_prompt.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.sessionManager,
    required this.onBack,
  });

  final HomeViewModel homeViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final SessionManager sessionManager;
  final VoidCallback onBack;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.sessionManager.isGuestMode()) {
      widget.homeViewModel.loadSavedFromApi();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Saved'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: FavoriteRecipesListView(
            homeViewModel: widget.homeViewModel,
            recipeViewModel: widget.recipeViewModel,
            groceryListViewModel: widget.groceryListViewModel,
            isGuest: widget.sessionManager.isGuestMode(),
            onGuestSignUpTap: () => goToSignup(context),
          ),
        );
      },
    );
  }
}
