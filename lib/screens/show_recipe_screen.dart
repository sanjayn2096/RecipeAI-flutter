import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/recipe_parsing.dart';
import '../data/models/recipe.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/recipe_view_model.dart';
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
  late bool _isSaved;
  late bool _isFavorited;
  late Recipe _displayRecipe;
  late final List<String> _ingredientItems;
  late final List<String> _instructionItems;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.recipe.isSaved;
    _isFavorited = widget.recipe.isFavorited;
    _displayRecipe = widget.recipe;
    _ingredientItems = widget.recipe.ingredients
        .map(RecipeParsing.formatIngredientLineForDisplay)
        .toList();
    _instructionItems = RecipeParsing.parseInstructions(widget.recipe.instructions);
  }

  Future<void> _toggleSaved() async {
    if (widget.isGuest) {
      final goSignup = await showGuestFavoriteSignupDialog(context);
      if (!mounted) return;
      if (goSignup == true) {
        goToSignup(context);
      }
      return;
    }
    final vm = widget.recipeViewModel;
    if (vm is! RecipeViewModel) return;
    final ok = await vm.toggleSaved(
      _displayRecipe.copyWith(isSaved: _isSaved),
    );
    if (!mounted) return;
    if (ok) {
      setState(() {
        _isSaved = !_isSaved;
        _displayRecipe = _displayRecipe.copyWith(isSaved: _isSaved);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSaved ? 'Saved to your list' : 'Removed from saved',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update saved list')),
      );
    }
  }

  Future<void> _togglePublicFavorite() async {
    if (widget.isGuest) {
      final goSignup = await showGuestFavoriteSignupDialog(context);
      if (!mounted) return;
      if (goSignup == true) {
        goToSignup(context);
      }
      return;
    }
    final vm = widget.recipeViewModel;
    if (vm is! RecipeViewModel) return;
    if (_displayRecipe.recipeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save this recipe first so it can be favorited'),
        ),
      );
      return;
    }
    final ok = await vm.togglePublicFavorite(
      _displayRecipe.copyWith(isFavorited: _isFavorited),
    );
    if (!mounted) return;
    if (ok) {
      final wasFav = _isFavorited;
      setState(() {
        _isFavorited = !wasFav;
        var n = _displayRecipe.favoriteCount;
        if (!wasFav) {
          n = n + 1;
        } else {
          n = n > 0 ? n - 1 : 0;
        }
        _displayRecipe = _displayRecipe.copyWith(
          isFavorited: _isFavorited,
          favoriteCount: n,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorited
                ? 'Thanks — this helps others discover the recipe'
                : 'Removed your public favorite',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update favorite')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groceryVm = widget.groceryListViewModel;
    final heroSize = (MediaQuery.sizeOf(context).width * 0.7).clamp(220.0, 320.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe.recipeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (widget.recipeViewModel != null) ...[
            IconButton(
              tooltip: _isSaved ? 'Remove from saved' : 'Save to your list',
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: _toggleSaved,
            ),
            IconButton(
              tooltip: _isFavorited
                  ? 'Remove public favorite'
                  : 'Favorite (helps trending)',
              icon: Icon(
                _isFavorited ? Icons.favorite : Icons.favorite_border,
                color: _isFavorited
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: _togglePublicFavorite,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: RecipeImageBox(
                imageUrl: _displayRecipe.image,
                width: heroSize,
                height: heroSize,
                fit: BoxFit.contain,
              ),
            ),
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
              'Values shown per serving.',
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
                  'recipe': _displayRecipe,
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
      _NutritionMetric(label: 'Calories', value: nutrition.calories),
      _NutritionMetric(label: 'Protein', value: nutrition.protein),
      _NutritionMetric(label: 'Carbs', value: nutrition.carbs),
      _NutritionMetric(label: 'Fat', value: nutrition.fat),
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

    final nutritionGrid = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tileRows,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 360;
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              nutritionGrid,
              const SizedBox(height: 12),
              _buildServingSizeCard(
                context,
                nutrition.numberOfServings,
                expandVertically: false,
                compact: false,
              ),
            ],
          );
        }
        // Measure the grid after layout and pin the servings column to that height.
        return _WideNutritionWithSide(
          nutritionGrid: nutritionGrid,
          buildSide: (ctx, columnHeight) => _buildWideSideColumn(
            ctx,
            columnHeight,
            nutrition.numberOfServings,
          ),
        );
      },
    );
  }

  /// Right column: servings only, height [columnHeight] to match the macro grid.
  Widget _buildWideSideColumn(
    BuildContext context,
    double columnHeight,
    int numberOfServings,
  ) {
    return SizedBox(
      height: columnHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildServingSizeCard(
              context,
              numberOfServings,
              expandVertically: true,
              compact: false,
            ),
          ),
        ],
      ),
    );
  }

  static const IconData _bowlIcon = Icons.ramen_dining_outlined;

  Widget _buildServingSizeCard(
    BuildContext context,
    int numberOfServings, {
    required bool expandVertically,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final n = numberOfServings < 1 ? 1 : numberOfServings;
    final accent = theme.colorScheme.primary;
    final smallBowl = compact
        ? 18.0
        : (expandVertically ? 26.0 : 22.0);
    final largeBowl = compact ? 26.0 : (expandVertically ? 40.0 : 30.0);
    final vPad = compact ? 8.0 : 12.0;
    final hPad = compact ? 10.0 : 12.0;
    final afterBowlsGap = compact ? 6.0 : (expandVertically ? 12.0 : 8.0);

    final content = Column(
      mainAxisSize: expandVertically ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment:
          expandVertically ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Text(
          'Servings',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        if (n <= 4)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: compact ? 3 : 4,
            runSpacing: compact ? 3 : 4,
            children: List<Widget>.generate(
              n,
              (_) => Icon(_bowlIcon, size: smallBowl, color: accent),
            ),
          )
        else
          Icon(_bowlIcon, size: largeBowl, color: accent),
        SizedBox(height: afterBowlsGap),
        Text(
          '$n',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: compact ? 20 : 22,
          ),
        ),
      ],
    );

    final decorated = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );

    if (expandVertically) {
      return SizedBox.expand(child: decorated);
    }
    return decorated;
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

  bool _isAvailableNutritionValue(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    return value.toLowerCase() != 'n/a';
  }
}

/// Sizes the side column to the measured height of [nutritionGrid] so the
/// macro tiles and servings share one bottom edge (avoids IntrinsicHeight
/// + [Expanded] on the grid under-reporting height).
class _WideNutritionWithSide extends StatefulWidget {
  const _WideNutritionWithSide({
    required this.nutritionGrid,
    required this.buildSide,
  });

  final Widget nutritionGrid;
  final Widget Function(BuildContext context, double columnHeight) buildSide;

  @override
  State<_WideNutritionWithSide> createState() => _WideNutritionWithSideState();
}

class _WideNutritionWithSideState extends State<_WideNutritionWithSide> {
  final GlobalKey _gridKey = GlobalKey();
  double? _measuredHeight;
  bool _measurementScheduled = false;

  void _scheduleMeasure() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final h = box.size.height;
      if (_measuredHeight == null || (h - _measuredHeight!).abs() > 0.5) {
        setState(() => _measuredHeight = h);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    const gap = 12.0;
    const sideW = 132.0;
    final columnH = _measuredHeight ?? 200.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final leftW = (constraints.maxWidth - gap - sideW).clamp(48.0, double.infinity);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: leftW,
              child: KeyedSubtree(
                key: _gridKey,
                child: widget.nutritionGrid,
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: sideW,
              height: columnH,
              child: widget.buildSide(context, columnH),
            ),
          ],
        );
      },
    );
  }
}

class _NutritionMetric {
  _NutritionMetric({required this.label, required this.value});

  final String label;
  final String value;
}
