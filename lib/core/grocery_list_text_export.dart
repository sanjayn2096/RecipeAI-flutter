import '../data/models/grocery_item.dart';
import 'grocery_ingredient_display.dart';
import 'grocery_ingredient_normalize.dart';

/// Plain-text export for share / clipboard.
abstract class GroceryListTextExport {
  GroceryListTextExport._();

  static String formatList(
    List<GroceryItem> items, {
    required String title,
    bool onlyUnchecked = false,
  }) {
    final filtered =
        onlyUnchecked ? items.where((e) => !e.isChecked).toList() : items;
    if (filtered.isEmpty) {
      return onlyUnchecked
          ? '(Nothing left to buy — all items are checked off.)'
          : '(Empty list)';
    }
    final buf = StringBuffer();
    buf.writeln(title);
    buf.writeln('');
    for (final item in filtered) {
      buf.writeln(formatLine(item));
    }
    return buf.toString().trimRight();
  }

  static String formatLine(GroceryItem item) {
    final parts = <String>[GroceryIngredientDisplay.listTitle(item.name)];
    final qty = item.quantity?.trim();
    final unit = item.unit?.trim();
    final qStr = (qty == null || qty.isEmpty) ? '1' : qty;
    if (unit != null && unit.isNotEmpty) {
      if (unit == GroceryIngredientNormalize.unitEach) {
        parts.add('($qStr unit)');
      } else {
        parts.add('($qStr $unit)');
      }
    } else if (qty != null && qty.isNotEmpty) {
      parts.add('($qty)');
    }
    if (item.note != null && item.note!.trim().isNotEmpty) {
      parts.add('— ${item.note!.trim()}');
    }
    return '• ${parts.join(' ')}';
  }
}
