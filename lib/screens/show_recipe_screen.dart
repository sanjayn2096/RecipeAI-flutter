import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../data/models/recipe.dart';
import '../widgets/guest_signup_prompt.dart';

class ShowRecipeScreen extends StatefulWidget {
  const ShowRecipeScreen({
    super.key,
    required this.recipe,
    this.recipeViewModel,
    this.isGuest = false,
  });

  final Recipe recipe;
  final dynamic recipeViewModel;
  final bool isGuest;

  @override
  State<ShowRecipeScreen> createState() => _ShowRecipeScreenState();
}

class _ShowRecipeScreenState extends State<ShowRecipeScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.recipe.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    if (widget.isGuest) {
      final goSignup = await showGuestFavoriteSignupDialog(context);
      if (!mounted) return;
      if (goSignup == true) {
        goToSignup(context);
      }
      return;
    }
    final vm = widget.recipeViewModel;
    if (vm == null) return;
    final ok = await vm.toggleFavorite(
      widget.recipe.copyWith(isFavorite: _isFavorite),
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.recipeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (widget.recipeViewModel != null)
            IconButton(
              tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipe.image.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.recipe.image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 200),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              widget.recipe.cookingTime,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.nutritionalValueOfDish,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Calories: ${widget.recipe.nutritionalValue.calories}, '
              'Protein: ${widget.recipe.nutritionalValue.protein}, '
              'Carbs: ${widget.recipe.nutritionalValue.carbs}, '
              'Fat: ${widget.recipe.nutritionalValue.fat}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingredients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(widget.recipe.ingredients),
            const SizedBox(height: 16),
            Text(
              AppStrings.recipeInstructions,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(widget.recipe.instructions),
          ],
        ),
      ),
    );
  }
}
