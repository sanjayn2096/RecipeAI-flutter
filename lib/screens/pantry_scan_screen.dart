import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'pantry/pantry_pick_photo.dart';
import '../core/app_strings.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/api/api_service.dart';
import '../view_models/grocery_list_view_model.dart';

/// Photo of pantry/fridge → Gemini on backend → user confirms items → grocery list.
///
/// Quantities from the model are suggestions only; users edit/remove rows before add.
class PantryScanScreen extends StatefulWidget {
  const PantryScanScreen({
    super.key,
    required this.apiService,
    required this.groceryListViewModel,
    required this.appTelemetry,
  });

  final ApiService apiService;
  final GroceryListViewModel groceryListViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<PantryScanScreen> createState() => _PantryScanScreenState();
}

class _PantryScanScreenState extends State<PantryScanScreen> {
  final _sessionId = const Uuid().v4();

  bool _busy = false;
  String? _error;
  List<_EditablePantryRow> _rows = [];

  Future<void> _pick(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = AppStrings.groceryPantryScanSignInRequired);
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

      final b64 = base64Encode(captured.bytes);
      final mime = captured.mimeType;

      final token = await user.getIdToken();
      final response = await widget.apiService.analyzePantryImage(
        imageBase64: b64,
        mimeType: mime,
        idToken: token,
      );

      final rows = response.items
          .map(
            (e) => _EditablePantryRow(
              source: e,
              selected: e.confidence == null || e.confidence! >= 0.35,
            ),
          )
          .toList();

      setState(() {
        _rows = rows;
        _busy = false;
        _error = rows.isEmpty ? AppStrings.groceryPantryScanNoItemsDetected : null;
      });

      if (rows.isNotEmpty) {
        await widget.appTelemetry.logFeatureInteraction(
          featureId: FeatureIds.groceryPantryScanAnalyze,
        );
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addSelected() async {
    final chosen = _rows.where((r) => r.selected).toList();
    if (chosen.isEmpty) return;

    final lines = <String>[];
    for (final r in chosen) {
      final line = r.source.toIngredientLine().trim();
      if (line.isNotEmpty) lines.add(line);
    }
    if (lines.isEmpty) return;

    await widget.groceryListViewModel.addLinesFromRecipe(
      lines: lines,
      recipeId: _sessionId,
      recipeName: AppStrings.groceryPantryScanSourceLabel,
    );

    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryPantryScanConfirmAdd,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.groceryPantryScanAdded(lines.length))),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.groceryPantryScanTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.groceryPantryScanSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text(AppStrings.groceryPantryScanTakePhoto),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text(AppStrings.groceryPantryScanChoosePhoto),
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(AppStrings.groceryPantryScanWorking),
                  ],
                ),
              ),
            ],
            if (_error != null && !_busy) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_rows.isNotEmpty && !_busy) ...[
              const SizedBox(height: 16),
              Text(
                AppStrings.groceryPantryScanReviewHeading,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final row = _rows[i];
                    final sub = _subtitle(row.source);
                    return CheckboxListTile(
                      value: row.selected,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _rows[i] = row.copyWith(selected: v));
                      },
                      title: Text(row.source.name),
                      subtitle: sub == null ? null : Text(sub),
                      secondary: IconButton(
                        tooltip: AppStrings.groceryPantryScanRemoveRow,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _rows = List.of(_rows)..removeAt(i);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: _rows.any((r) => r.selected) ? _addSelected : null,
                child: const Text(AppStrings.groceryPantryScanAddSelected),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _subtitle(PantryScanItem item) {
    final parts = <String>[];
    final q = item.quantity.trim();
    final u = item.unit.trim();
    if (q.isNotEmpty || u.isNotEmpty) {
      parts.add([q, u].where((s) => s.isNotEmpty).join(' ').trim());
    }
    if (item.confidence != null) {
      parts.add(
        '${AppStrings.groceryPantryScanConfidence} ${(item.confidence! * 100).round()}%',
      );
    }
    if (item.notes.isNotEmpty) parts.add(item.notes);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

class _EditablePantryRow {
  const _EditablePantryRow({
    required this.source,
    required this.selected,
  });

  final PantryScanItem source;
  final bool selected;

  _EditablePantryRow copyWith({bool? selected}) => _EditablePantryRow(
        source: source,
        selected: selected ?? this.selected,
      );
}
