import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/recipe_parsing.dart';
import '../data/models/recipe.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/guest_signup_prompt.dart';
import '../widgets/recipe_image_box.dart';

class ShowRecipeScreen extends StatefulWidget {
  const ShowRecipeScreen({
    super.key,
    required this.recipe,
    this.recipeViewModel,
    this.groceryListViewModel,
    this.isGuest = false,
  });

  final Recipe recipe;
  final dynamic recipeViewModel;
  final GroceryListViewModel? groceryListViewModel;
  final bool isGuest;

  @override
  State<ShowRecipeScreen> createState() => _ShowRecipeScreenState();
}

class _ShowRecipeScreenState extends State<ShowRecipeScreen> {
  late bool _isFavorite;
  late final List<String> _ingredientItems;
  late final List<String> _instructionItems;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.recipe.isFavorite;
    _ingredientItems = widget.recipe.ingredients
        .map(RecipeParsing.formatIngredientLineForDisplay)
        .toList();
    _instructionItems = RecipeParsing.parseInstructions(widget.recipe.instructions);
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
    final groceryVm = widget.groceryListViewModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.recipeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
            RecipeImageBox(imageUrl: widget.recipe.image),
            const SizedBox(height: 16),
            Text(
              widget.recipe.cookingTime,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.nutritionalValueOfDish,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 4),
            Text(
              'Values shown per Serving (${widget.recipe.nutritionalValue.numberOfServings} servings total).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            _buildNutritionSection(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(
                '/cook-recipe',
                extra: {
                  'recipe': widget.recipe,
                  'groceryListViewModel': groceryVm,
                },
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text("Let's get cooking"),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ingredients',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 4),
            _buildIngredientsSection(),
            const SizedBox(height: 16),
            Text(
              AppStrings.recipeInstructions,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 19),
            ),
            const SizedBox(height: 4),
            _buildInstructionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection() {
    if (_ingredientItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _ingredientItems.map(_buildBulletLine).toList(),
    );
  }

  Widget _buildInstructionsSection() {
    if (_instructionItems.isEmpty) {
      return Text(widget.recipe.instructions);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        _instructionItems.length,
        (index) => _buildNumberedLine(index + 1, _instructionItems[index]),
      ),
    );
  }

  Widget _buildBulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 2),
            child: Text(
              '•',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedLine(int index, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$index. '),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    final nutrition = widget.recipe.nutritionalValue;
    final metrics = <_NutritionMetric>[
      _NutritionMetric(
        label: 'Calories',
        value: nutrition.calories,
        dotsFilled: _dotLevelForCalories(nutrition.calories),
      ),
      _NutritionMetric(
        label: 'Protein',
        value: nutrition.protein,
        dotsFilled: _dotLevelForMacro(nutrition.protein),
      ),
      _NutritionMetric(
        label: 'Carbs',
        value: nutrition.carbs,
        dotsFilled: _dotLevelForMacro(nutrition.carbs),
      ),
      _NutritionMetric(
        label: 'Fat',
        value: nutrition.fat,
        dotsFilled: _dotLevelForMacro(nutrition.fat),
      ),
    ].where((m) => _isAvailableNutritionValue(m.value)).toList();

    if (metrics.isEmpty) {
      return Text(
        'Nutritional values unavailable.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final tileRows = <Widget>[];
    for (var i = 0; i < metrics.length; i += 2) {
      final left = metrics[i];
      final right = (i + 1 < metrics.length) ? metrics[i + 1] : null;
      tileRows.add(
        Row(
          children: [
            Expanded(
              child: _buildNutritionTile(label: left.label, value: left.value),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: right == null
                  ? const SizedBox.shrink()
                  : _buildNutritionTile(label: right.label, value: right.value),
            ),
          ],
        ),
      );
      if (i + 2 < metrics.length) {
        tileRows.add(const SizedBox(height: 10));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...tileRows,
        const SizedBox(height: 14),
        ...List.generate(metrics.length, (index) {
          final metric = metrics[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == metrics.length - 1 ? 0 : 8),
            child: _buildNutritionScaleRow(
              label: metric.label,
              dotsFilled: metric.dotsFilled,
            ),
          );
        }),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(
              'Servings: ${nutrition.numberOfServings}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
              ),
            ),
            if (_isAvailableNutritionValue(nutrition.vitamins))
              Text(
                'Vitamins: ${nutrition.vitamins}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                ),
              ),
          ],
        ),
      ],
    );
  }

  bool _isAvailableNutritionValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    return value.toLowerCase() != 'n/a';
  }

  Widget _buildNutritionTile({required String label, required String value}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionScaleRow({
    required String label,
    required int dotsFilled,
  }) {
    final theme = Theme.of(context);
    final safeDots = dotsFilled.clamp(0, 5);
    return Row(
      children: [
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
        ),
        ...List.generate(5, (index) {
          final isFilled = index < safeDots;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              Icons.circle,
              size: 9,
              color: isFilled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          );
        }),
      ],
    );
  }

  int _dotLevelForMacro(String raw) {
    final value = _extractLeadingNumber(raw);
    if (value == null) return 0;
    if (value < 10) return 1;
    if (value < 20) return 2;
    if (value < 35) return 3;
    if (value < 50) return 4;
    return 5;
  }

  int _dotLevelForCalories(String raw) {
    final value = _extractLeadingNumber(raw);
    if (value == null) return 0;
    if (value < 200) return 1;
    if (value < 350) return 2;
    if (value < 500) return 3;
    if (value < 700) return 4;
    return 5;
  }

  double? _extractLeadingNumber(String raw) {
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }
}

class _NutritionMetric {
  _NutritionMetric({
    required this.label,
    required this.value,
    required this.dotsFilled,
  });

  final String label;
  final String value;
  final int dotsFilled;
}
