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
    this.coachImportLinksKey,
    this.coachImportPasteKey,
    this.coachImportScanKey,
  });

  final SessionManager sessionManager;
  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;

  /// Optional spotlight targets for the first-time Import tab coach overlay.
  final GlobalKey? coachImportLinksKey;
  final GlobalKey? coachImportPasteKey;
  final GlobalKey? coachImportScanKey;

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
      GlobalKey? coachKey,
      required IconData icon,
      required String title,
      required String tooltip,
      required VoidCallback onTap,
    }) {
      final textTheme = Theme.of(context).textTheme;
      final child = Tooltip(
        message: tooltip,
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.primary, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 36,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (coachKey != null) {
        return KeyedSubtree(key: coachKey, child: child);
      }
      return child;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: tile(
                          coachKey: coachImportLinksKey,
                          icon: Icons.link_rounded,
                          title: AppStrings.importHubTileLinks,
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
                          coachKey: coachImportPasteKey,
                          icon: Icons.format_quote_rounded,
                          title: AppStrings.importHubTilePaste,
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
                    coachKey: coachImportScanKey,
                    icon: Icons.document_scanner_outlined,
                    title: AppStrings.importHubTileScan,
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
