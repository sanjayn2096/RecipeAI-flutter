import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import '../data/models/recipe.dart';

class ShowRecipeScreen extends StatefulWidget {
  const ShowRecipeScreen({
    super.key,
    required this.recipe,
    this.recipeViewModel,
  });

  final Recipe recipe;
  final dynamic recipeViewModel;

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

  void _toggleFavorite() {
    widget.recipeViewModel?.saveFavorite(
      widget.recipe.copyWith(isFavorite: true),
    );
    setState(() => _isFavorite = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites')),
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
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: _isFavorite ? null : _toggleFavorite,
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
