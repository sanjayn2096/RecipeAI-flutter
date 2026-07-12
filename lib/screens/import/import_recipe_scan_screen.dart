import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/l10n_context.dart';
import '../../core/telemetry/app_telemetry.dart';
import '../../data/api/api_service.dart';
import '../../view_models/grocery_list_view_model.dart';
import '../../view_models/recipe_view_model.dart';
import '../../view_models/subscription_view_model.dart';
import 'ocr_recognize_recipe.dart';
import '../pantry/pantry_pick_photo.dart';
import '../show_recipe_screen.dart';

class ImportRecipeScanScreen extends StatefulWidget {
  const ImportRecipeScanScreen({
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
  State<ImportRecipeScanScreen> createState() => _ImportRecipeScanScreenState();
}

class _ImportRecipeScanScreenState extends State<ImportRecipeScanScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = context.l10n.importRecipeSignInRequired);
      return;
    }

    if (kIsWeb) {
      setState(() => _error = context.l10n.importRecipeWebScanUnsupported);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final captured = await pickPantryPhoto(source);
      if (captured == null || captured.bytes.isEmpty) {
        setState(() => _busy = false);
        return;
      }

      final ocrText = await recognizeRecipeTextFromBytes(
        captured.bytes,
        captured.mimeType,
      );
      if (ocrText == null || ocrText.trim().length < 15) {
        setState(() {
          _error = context.l10n.importRecipeOcrEmpty;
          _busy = false;
        });
        return;
      }

      final recipe = await widget.recipeViewModel.importRecipe(
        mode: 'text',
        plainText: ocrText,
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
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Icon(
          Icons.document_scanner_outlined,
          color: scheme.primary,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 48,
              color: scheme.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy || kIsWeb
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy || kIsWeb
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Photos'),
                  ),
                ),
              ],
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 16),
              Text(
                context.l10n.importRecipeWebScanUnsupported,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 28),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              Text(
                context.l10n.importRecipeBusy,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (_error != null && !_busy) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: scheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
