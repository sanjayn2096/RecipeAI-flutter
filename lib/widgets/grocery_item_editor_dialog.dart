import 'package:flutter/material.dart';

import '../core/l10n_context.dart';
import '../core/grocery_ingredient_normalize.dart';
import '../data/models/grocery_item.dart';

/// Units shown in add/edit grocery dialogs (canonical value → label).
const List<(String, String)> kGroceryUnitChoices = [
  (GroceryIngredientNormalize.unitEach, 'Unit'),
  ('kg', 'Kilogram'),
  ('g', 'Gram'),
  ('L', 'Litre'),
  ('ml', 'Millilitre'),
  ('lb', 'Pound'),
  ('oz', 'Ounce'),
];

/// Result of [showGroceryItemEditorDialog].
class GroceryItemFormResult {
  const GroceryItemFormResult({
    required this.name,
    required this.quantity,
    required this.unit,
    this.note,
  });

  final String name;
  final String quantity;
  final String unit;
  final String? note;
}

Future<GroceryItemFormResult?> showGroceryItemEditorDialog(
  BuildContext context, {
  GroceryItem? initial,
  required bool isEdit,
}) {
  return showDialog<GroceryItemFormResult>(
    context: context,
    builder: (ctx) => _GroceryItemEditorDialog(
      initial: initial,
      isEdit: isEdit,
    ),
  );
}

class _GroceryItemEditorDialog extends StatefulWidget {
  const _GroceryItemEditorDialog({
    required this.initial,
    required this.isEdit,
  });

  final GroceryItem? initial;
  final bool isEdit;

  @override
  State<_GroceryItemEditorDialog> createState() => _GroceryItemEditorDialogState();
}

class _GroceryItemEditorDialogState extends State<_GroceryItemEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;
  late int _quantity;
  late String _unitValue;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nameCtrl = TextEditingController(text: i?.name ?? '');
    _noteCtrl = TextEditingController(text: i?.note ?? '');
    _quantity = 1;
    if (i?.quantity != null && i!.quantity!.isNotEmpty) {
      final p = int.tryParse(i.quantity!.trim());
      if (p != null && p >= 1 && p <= 100) {
        _quantity = p;
      }
    }
    _unitValue = i?.unit?.trim().isNotEmpty == true
        ? i!.unit!.trim()
        : GroceryIngredientNormalize.unitEach;
    if (!kGroceryUnitChoices.any((e) => e.$1 == _unitValue)) {
      _unitValue = GroceryIngredientNormalize.unitEach;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(
        widget.isEdit ? l10n.groceryEditItem : l10n.groceryAddItem,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: l10n.groceryFieldName,
                  hintText: l10n.groceryNameSearchHint,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _quantity,
                decoration: InputDecoration(
                  labelText: l10n.groceryFieldQuantity,
                ),
                items: List.generate(
                  100,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('${i + 1}'),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _quantity = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _unitValue,
                decoration: InputDecoration(
                  labelText: l10n.groceryFieldUnit,
                ),
                items: kGroceryUnitChoices
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.$1,
                        child: Text('${e.$2} (${e.$1})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _unitValue = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: l10n.groceryFieldNoteOptional,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.back),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              GroceryItemFormResult(
                name: name,
                quantity: '$_quantity',
                unit: _unitValue,
                note: _noteCtrl.text.trim().isEmpty
                    ? null
                    : _noteCtrl.text.trim(),
              ),
            );
          },
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
