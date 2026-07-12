import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n_context.dart';
import '../../core/telemetry/app_telemetry.dart';
import '../../data/api/api_service.dart';
import '../../view_models/grocery_list_view_model.dart';
import '../../view_models/recipe_view_model.dart';
import '../../view_models/subscription_view_model.dart';
import '../show_recipe_screen.dart';

class ImportRecipeTextScreen extends StatefulWidget {
  const ImportRecipeTextScreen({
    super.key,
    required this.recipeViewModel,
    required this.groceryListViewModel,
    required this.apiService,
    required this.appTelemetry,
    required this.subscriptionViewModel,
    required this.isGuest,
  });

  final RecipeViewModel recipeViewModel;
  final GroceryListViewModel groceryListViewModel;
  final ApiService apiService;
  final AppTelemetry appTelemetry;
  final SubscriptionViewModel subscriptionViewModel;
  final bool isGuest;

  @override
  State<ImportRecipeTextScreen> createState() => _ImportRecipeTextScreenState();
}

class _ImportRecipeTextScreenState extends State<ImportRecipeTextScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    final raw = _controller.text.trim();
    if (raw.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.importRecipeNeedMoreText)),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final recipe = await widget.recipeViewModel.importRecipe(
        mode: 'text',
        plainText: raw,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (ctx) => ShowRecipeScreen(
            recipe: recipe,
            apiService: widget.apiService,
            appTelemetry: widget.appTelemetry,
            subscriptionViewModel: widget.subscriptionViewModel,
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
        title: Icon(
          Icons.format_quote_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).pasteButtonLabel,
            icon: const Icon(Icons.content_paste_rounded),
            onPressed: _busy
                ? null
                : () async {
                    final clip = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clip?.text != null && clip!.text!.trim().isNotEmpty) {
                      setState(() => _controller.text = clip.text!);
                    }
                  },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_busy,
                expands: true,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: context.l10n.importRecipePasteHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    ? context.l10n.importRecipeBusy
                    : context.l10n.importRecipeExtract,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
