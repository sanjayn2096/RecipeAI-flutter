import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_strings.dart';
import '../../services/session_manager.dart';
import '../../view_models/grocery_list_view_model.dart';
import '../../view_models/recipe_view_model.dart';
import '../../widgets/guest_signup_prompt.dart';
import 'import_recipe_link_screen.dart';
import 'import_recipe_scan_screen.dart';
import 'import_recipe_text_screen.dart';

/// Hub: icon shortcuts to link, paste, and cookbook photo flows.
class ImportHubScreen extends StatelessWidget {
  const ImportHubScreen({
    super.key,
    required this.sessionManager,
    required this.recipeViewModel,
    required this.groceryListViewModel,
  });

  final SessionManager sessionManager;
  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;

  Future<bool> _allowImport(BuildContext context) async {
    if (sessionManager.isGuestMode()) {
      final signup = await showGuestImportSignupDialog(context);
      if (!context.mounted) return false;
      if (signup == true) goToSignup(context);
      return false;
    }
    if (FirebaseAuth.instance.currentUser == null) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.importRecipeSignInRequired)),
      );
      return false;
    }
    return true;
  }

  Future<void> _push(BuildContext context, Widget child) async {
    if (!await _allowImport(context) || !context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget tile({
      required IconData icon,
      required String tooltip,
      required VoidCallback onTap,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Center(
              child: Icon(
                icon,
                size: 40,
                color: scheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: tile(
                          icon: Icons.link_rounded,
                          tooltip: 'Paste a recipe link — web or social',
                          onTap: () => _push(
                            context,
                            ImportRecipeLinkScreen(
                              recipeViewModel: recipeViewModel,
                              groceryListViewModel: groceryListViewModel,
                              isGuest: sessionManager.isGuestMode(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: tile(
                          icon: Icons.format_quote_rounded,
                          tooltip: 'Paste caption or recipe text',
                          onTap: () => _push(
                            context,
                            ImportRecipeTextScreen(
                              recipeViewModel: recipeViewModel,
                              groceryListViewModel: groceryListViewModel,
                              isGuest: sessionManager.isGuestMode(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: tile(
                    icon: Icons.document_scanner_outlined,
                    tooltip: 'Scan a cookbook page or recipe card',
                    onTap: () => _push(
                      context,
                      ImportRecipeScanScreen(
                        recipeViewModel: recipeViewModel,
                        groceryListViewModel: groceryListViewModel,
                        isGuest: sessionManager.isGuestMode(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
