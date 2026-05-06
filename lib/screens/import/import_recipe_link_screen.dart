import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_strings.dart';
import '../../data/api/api_service.dart';
import '../../view_models/grocery_list_view_model.dart';
import '../../view_models/recipe_view_model.dart';
import '../show_recipe_screen.dart';

class ImportRecipeLinkScreen extends StatefulWidget {
  const ImportRecipeLinkScreen({
    super.key,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.isGuest,
  });

  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final bool isGuest;

  @override
  State<ImportRecipeLinkScreen> createState() => _ImportRecipeLinkScreenState();
}

class _ImportRecipeLinkScreenState extends State<ImportRecipeLinkScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.importRecipeNeedUrl)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final recipe = await widget.recipeViewModel.importRecipe(
        mode: 'url',
        url: raw,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (ctx) => ShowRecipeScreen(
            recipe: recipe,
            recipeViewModel: widget.recipeViewModel,
            groceryListViewModel: widget.groceryListViewModel,
            isGuest: widget.isGuest,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(Icons.link_rounded, color: Theme.of(context).colorScheme.primary),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _busy ? null : _extract(),
              decoration: InputDecoration(
                hintText: AppStrings.importRecipeFromLinkHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  tooltip: MaterialLocalizations.of(context).pasteButtonLabel,
                  icon: const Icon(Icons.content_paste_rounded),
                  onPressed: _busy
                      ? null
                      : () async {
                          final clip = await Clipboard.getData(
                            Clipboard.kTextPlain,
                          );
                          if (clip?.text?.trim().isNotEmpty ?? false) {
                            setState(() {
                              _controller.text = clip!.text!;
                            });
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _busy ? null : _extract,
              icon: _busy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(
                _busy
                    ? AppStrings.importRecipeBusy
                    : AppStrings.importRecipeExtract,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
