import 'package:flutter/material.dart';

import '../view_models/home_view_model.dart';
import '../widgets/favorite_recipes_list_view.dart';

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
    widget.homeViewModel.loadFavoritesFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("User's Favorites"),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
          ),
          body: FavoriteRecipesListView(
            homeViewModel: widget.homeViewModel,
            recipeViewModel: widget.recipeViewModel,
          ),
        );
      },
    );
  }
}
