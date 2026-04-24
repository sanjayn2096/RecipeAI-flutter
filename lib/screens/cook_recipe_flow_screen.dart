import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../core/recipe_parsing.dart';
import '../data/models/recipe.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/recipe_view_model.dart';

/// Full-screen cooking mode: gather ingredients → step-by-step → Fin.
class CookRecipeFlowScreen extends StatefulWidget {
  const CookRecipeFlowScreen({
    super.key,
    required this.recipe,
    this.groceryListViewModel,
    this.recipeViewModel,
  });

  final Recipe recipe;
  final GroceryListViewModel? groceryListViewModel;

  /// Used to read cache and POST single step images (signed-in).
  final dynamic recipeViewModel;

  @override
  State<CookRecipeFlowScreen> createState() => _CookRecipeFlowScreenState();
}

class _CookRecipeFlowScreenState extends State<CookRecipeFlowScreen> {
  late final List<String> _ingredients;
  late final List<String> _instructions;

  final Set<int> _checkedIngredientIndices = {};
  int _pageIndex = 0;
  /// Per-step image URLs; filled from [Recipe] / cache, then on-demand.
  late List<String> _stepDisplayUrls;
  final Set<int> _stepLoadInFlight = {};

  int get _gatherPage => 0;
  int get _firstInstructionPage => 1;
  int get _finPage => 1 + _instructions.length;

  int get _stepCount {
    if (_instructions.isNotEmpty) {
      return _instructions.length;
    }
    return widget.recipe.instructions.trim().isNotEmpty ? 1 : 0;
  }

  @override
  void initState() {
    super.initState();
    _ingredients = widget.recipe.ingredients
        .map(RecipeParsing.formatIngredientLineForDisplay)
        .toList();

    _instructions = RecipeParsing.parseInstructions(widget.recipe.instructions);
    final insRaw = widget.recipe.instructions.trim();
    if (_instructions.isEmpty && insRaw.isNotEmpty) {
      _instructions = [insRaw];
    }
    final n = _stepCount;
    _stepDisplayUrls = n > 0 ? List<String>.filled(n, '') : <String>[];
    final fromRecipe = widget.recipe.stepImageUrls;
    for (var i = 0; i < n && i < fromRecipe.length; i++) {
      final t = fromRecipe[i].trim();
      if (t.isNotEmpty) {
        _stepDisplayUrls[i] = t;
      }
    }
    unawaited(_mergeCachedStepUrls());
  }

  Future<void> _mergeCachedStepUrls() async {
    final vm = widget.recipeViewModel;
    if (vm is! RecipeViewModel) return;
    final r = await vm.recipeWithCachedImages(widget.recipe);
    if (!mounted) return;
    if (r.stepImageUrls.isEmpty) return;
    setState(() {
      for (var i = 0; i < _stepDisplayUrls.length && i < r.stepImageUrls.length; i++) {
        if (r.stepImageUrls[i].trim().isNotEmpty) {
          _stepDisplayUrls[i] = r.stepImageUrls[i].trim();
        }
      }
    });
  }

  void _goBackInFlow() {
    if (_pageIndex > _gatherPage) {
      setState(() => _pageIndex--);
    } else {
      if (mounted) context.pop();
    }
  }

  void _exitCooking() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit cooking?'),
        content: const Text(
          'You can come back anytime from the recipe screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) context.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _nextFromGather() {
    setState(() => _pageIndex = _firstInstructionPage);
    final vm = widget.recipeViewModel;
    if (vm is RecipeViewModel) {
      vm.prefetchNextStepIfNeeded(widget.recipe, 0);
    }
  }

  void _requestStepIfNeeded(int safeIdx) {
    if (safeIdx < 0 || safeIdx >= _stepDisplayUrls.length) return;
    if (_stepDisplayUrls[safeIdx].trim().isNotEmpty) return;
    if (_stepLoadInFlight.contains(safeIdx)) return;
    final vm = widget.recipeViewModel;
    if (vm is! RecipeViewModel) return;
    _stepLoadInFlight.add(safeIdx);
    unawaited(() async {
      try {
        final u = await vm.ensureStepImageUrl(
          recipe: widget.recipe,
          stepIndex: safeIdx,
        );
        if (!mounted) return;
        setState(() {
          _stepDisplayUrls[safeIdx] = u;
          _stepLoadInFlight.remove(safeIdx);
        });
        vm.prefetchNextStepIfNeeded(widget.recipe, safeIdx);
      } catch (_) {
        if (mounted) {
          setState(() => _stepLoadInFlight.remove(safeIdx));
        } else {
          _stepLoadInFlight.remove(safeIdx);
        }
      }
    }());
  }

  void _nextFromInstruction() {
    if (_pageIndex < _finPage - 1) {
      setState(() => _pageIndex++);
    } else {
      setState(() => _pageIndex = _finPage);
    }
  }

  void _cookAgain() {
    setState(() {
      _pageIndex = _gatherPage;
      _checkedIngredientIndices.clear();
    });
  }

  void _showFullRecipeDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.recipe.recipeName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingredients',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildIngredientList(_ingredients),
              const SizedBox(height: 16),
              Text(
                'Instructions',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildInstructionList(_instructions, widget.recipe.instructions),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientList(List<String> items) {
    if (items.isEmpty) {
      return const Text('No ingredients listed.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10, top: 2),
                    child: Text('•', style: Theme.of(context).textTheme.bodyLarge),
                  ),
                  Expanded(
                    child: Text(item, style: Theme.of(context).textTheme.bodyLarge),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildInstructionList(List<String> items, String fallback) {
    if (items.isEmpty) return Text(fallback);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        items.length,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${index + 1}. '),
              Expanded(child: Text(items[index])),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pageIndex == _gatherPage,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_pageIndex > _gatherPage) {
          setState(() => _pageIndex--);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_appBarTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackInFlow,
          ),
          actions: [
            TextButton(
              onPressed: _exitCooking,
              child: const Text('Exit'),
            ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  String get _appBarTitle {
    if (_pageIndex == _gatherPage) return 'Gather ingredients';
    if (_pageIndex == _finPage) return 'All done';
    final step = _pageIndex - _firstInstructionPage + 1;
    return 'Step $step of ${_instructions.length}';
  }

  Widget _buildBody(BuildContext context) {
    if (_pageIndex == _gatherPage) {
      return _buildGatherPage(context);
    }
    if (_pageIndex == _finPage) {
      return _buildFinPage(context);
    }
    return _buildInstructionPage(context);
  }

  Widget _buildGatherPage(BuildContext context) {
    final theme = Theme.of(context);
    final total = _ingredients.length;
    final checked = _checkedIngredientIndices.length;
    final progress = total == 0 ? 1.0 : checked / total;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.recipe.recipeName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? 'No ingredient list to check off — continue when ready.'
                : 'Tick off each ingredient as you gather it.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              '$checked / $total gathered',
              style: theme.textTheme.labelMedium,
            ),
          ],
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _showFullRecipeDialog,
            icon: const Icon(Icons.article_outlined),
            label: const Text('View full recipe text'),
          ),
          Expanded(
            child: total == 0
                ? const Center(
                    child: Icon(Icons.restaurant_menu, size: 56),
                  )
                : ListView.builder(
                    itemCount: total,
                    itemBuilder: (_, i) {
                      final ing = _ingredients[i];
                      final isChecked = _checkedIngredientIndices.contains(i);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                _checkedIngredientIndices.add(i);
                              } else {
                                _checkedIngredientIndices.remove(i);
                              }
                            });
                          },
                          title: Text(ing),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          if (total > 0 && widget.groceryListViewModel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton.icon(
                onPressed: _addStillNeededToGroceryFromGather,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text(AppStrings.cookFlowAddUncheckedToGrocery),
              ),
            ),
          FilledButton.icon(
            onPressed: _nextFromGather,
            icon: const Icon(Icons.arrow_forward),
            label: const Text("I'm ready"),
          ),
        ],
      ),
    );
  }

  Future<void> _addStillNeededToGroceryFromGather() async {
    final vm = widget.groceryListViewModel;
    if (vm == null) return;
    final need = <String>[];
    for (var i = 0; i < _ingredients.length; i++) {
      if (!_checkedIngredientIndices.contains(i)) {
        need.add(_ingredients[i]);
      }
    }
    if (need.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You marked every ingredient as gathered. Uncheck items you still need to buy.',
          ),
        ),
      );
      return;
    }
    await vm.addLinesFromRecipe(
      lines: need,
      recipeId: widget.recipe.recipeId,
      recipeName: widget.recipe.recipeName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.recipeAddedToGroceryList)),
    );
  }

  Widget _buildInstructionPage(BuildContext context) {
    final idx = _pageIndex - _firstInstructionPage;
    final safeIdx = _instructions.isEmpty
        ? 0
        : idx.clamp(0, _instructions.length - 1);
    final text = _instructions.isEmpty
        ? widget.recipe.instructions
        : _instructions[safeIdx];
    final theme = Theme.of(context);
    final isLastInstruction =
        _instructions.isEmpty || safeIdx >= _instructions.length - 1;
    String? stepImageUrl;
    if (safeIdx < _stepDisplayUrls.length) {
      final u = _stepDisplayUrls[safeIdx].trim();
      if (u.isNotEmpty &&
          (u.toLowerCase().startsWith('http://') ||
              u.toLowerCase().startsWith('https://'))) {
        stepImageUrl = u;
      }
    }
    final hasVm = widget.recipeViewModel is RecipeViewModel;
    if (hasVm &&
        stepImageUrl == null &&
        safeIdx < _stepDisplayUrls.length &&
        _stepDisplayUrls[safeIdx].trim().isEmpty &&
        !_stepLoadInFlight.contains(safeIdx)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestStepIfNeeded(safeIdx);
        }
      });
    }
    final loading =
        hasVm && stepImageUrl == null && _stepLoadInFlight.contains(safeIdx);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_instructions.isEmpty)
            Text(
              'Steps',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            )
          else
            Text(
              '${idx + 1} / ${_instructions.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          if (loading) ...[
            const SizedBox(height: 12),
            const AspectRatio(
              aspectRatio: 1,
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (stepImageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  stepImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                text,
                style: theme.textTheme.titleLarge?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                onPressed: _goBackInFlow,
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _nextFromInstruction,
                  child: Text(isLastInstruction ? 'Finish' : 'Next'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinPage(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Fin.',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hope it tastes amazing.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _cookAgain,
            child: const Text('Cook again'),
          ),
        ],
      ),
    );
  }
}
