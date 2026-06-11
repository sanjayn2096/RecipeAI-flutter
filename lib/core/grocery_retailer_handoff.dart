import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/instacart_coming_soon_sheet.dart';
import 'grocery_list_text_export.dart';
import '../data/models/grocery_item.dart';

/// How the user shops for missing meal-plan items outside the app.
abstract class GroceryRetailerHandoff {
  Future<void> execute(BuildContext context);
}

/// Copy formatted lines to the clipboard.
class CopyListHandoff implements GroceryRetailerHandoff {
  CopyListHandoff(this.lines);

  final List<String> lines;

  @override
  Future<void> execute(BuildContext context) async {
    if (lines.isEmpty) return;
    final text = lines.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shopping list copied')),
    );
  }
}

/// Copy from grocery items (name + qty).
class CopyGroceryItemsHandoff implements GroceryRetailerHandoff {
  CopyGroceryItemsHandoff(this.items);

  final List<GroceryItem> items;

  @override
  Future<void> execute(BuildContext context) async {
    final lines = items
        .map(GroceryListTextExport.formatLine)
        .where((s) => s.trim().isNotEmpty)
        .toList();
    await CopyListHandoff(lines).execute(context);
  }
}

/// Instacart integration placeholder — no network calls.
class InstacartHandoff implements GroceryRetailerHandoff {
  @override
  Future<void> execute(BuildContext context) async {
    await showInstacartComingSoonSheet(context);
  }
}
