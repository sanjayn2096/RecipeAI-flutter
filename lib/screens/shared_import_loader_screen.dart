import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n_context.dart';
import '../data/api/api_service.dart';
import '../navigation/pending_shared_import.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/recipe_view_model.dart';

/// Runs [RecipeViewModel.importRecipe] for a share-sheet payload, then `/show-recipe`.
class SharedImportLoaderScreen extends StatefulWidget {
  const SharedImportLoaderScreen({
    super.key,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.isGuest,
    this.payload,
  });

  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final bool isGuest;
  final PendingSharedImportPayload? payload;

  @override
  State<SharedImportLoaderScreen> createState() =>
      _SharedImportLoaderScreenState();
}

class _SharedImportLoaderScreenState extends State<SharedImportLoaderScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    final payload = widget.payload ?? PendingSharedImport.take();
    if (payload == null) {
      setState(() => _error = 'missing_payload');
      return;
    }
    if (widget.isGuest) {
      PendingSharedImport.set(payload);
      if (!mounted) return;
      context.go('/login');
      return;
    }

    try {
      final recipe = await widget.recipeViewModel.importRecipe(
        mode: payload.mode,
        url: payload.url,
        plainText: payload.plainText,
        telemetryAction: 'share_intent',
      );
      if (!mounted) return;
      context.go(
        '/show-recipe',
        extra: {
          'recipe': recipe,
          'recipeViewModel': widget.recipeViewModel,
          'groceryListViewModel': widget.groceryListViewModel,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final message = _error == 'missing_payload'
          ? context.l10n.sharedImportMissingPayload
          : _error.toString();
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.importRecipeTabTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: Text(context.l10n.sharedImportGoHome),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.importRecipeBusy),
          ],
        ),
      ),
    );
  }
}
