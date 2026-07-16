import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/telemetry/app_telemetry.dart';
import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../data/repositories/user_repository.dart';
import '../services/session_manager.dart';
import '../view_models/grocery_list_view_model.dart';
import '../view_models/subscription_view_model.dart';

/// Loads a recipe by id from a shared link, then replaces with `/show-recipe`.
class SharedRecipeLoaderScreen extends StatefulWidget {
  const SharedRecipeLoaderScreen({
    super.key,
    required this.recipeId,
    required this.apiService,
    required this.userRepository,
    required this.sessionManager,
    required this.appTelemetry,
    required this.subscriptionViewModel,
    this.recipeViewModel,
    this.groceryListViewModel,
  });

  final String recipeId;
  final ApiService apiService;
  final UserRepository userRepository;
  final SessionManager sessionManager;
  final AppTelemetry appTelemetry;
  final SubscriptionViewModel subscriptionViewModel;
  final dynamic recipeViewModel;
  final GroceryListViewModel? groceryListViewModel;

  @override
  State<SharedRecipeLoaderScreen> createState() =>
      _SharedRecipeLoaderScreenState();
}

class _SharedRecipeLoaderScreenState extends State<SharedRecipeLoaderScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    final id = widget.recipeId.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Missing recipe id');
      return;
    }
    try {
      late final Recipe recipe;
      if (widget.sessionManager.isGuestMode()) {
        recipe = await widget.apiService.getPublicRecipe(id);
      } else {
        try {
          recipe = await widget.userRepository.fetchRecipeById(id);
        } catch (_) {
          // Fallback if token missing or auth get-recipe fails.
          recipe = await widget.apiService.getPublicRecipe(id);
        }
      }
      if (!mounted) return;
      context.go(
        '/show-recipe',
        extra: {
          'recipe': recipe,
          'recipeViewModel': widget.recipeViewModel,
          'groceryListViewModel': widget.groceryListViewModel,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not open this shared recipe.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go home'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
