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

  /// Clubs similar ingredients across all recipes into one line (e.g. Garlic ×3).
  static String formatAllClubbed(
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

    final groups = <String, List<GroceryItem>>{};
    final order = <String>[];
    for (final item in filtered) {
      final k = GroceryIngredientDisplay.baseIngredientKey(item.name);
      groups.putIfAbsent(k, () {
        order.add(k);
        return <GroceryItem>[];
      }).add(item);
    }

    // Prefer stable + readable output: alphabetical by display title.
    order.sort((a, b) {
      final ta = _clubbedGroupTitle(groups[a]!);
      final tb = _clubbedGroupTitle(groups[b]!);
      return ta.toLowerCase().compareTo(tb.toLowerCase());
    });

    final buf = StringBuffer();
    buf.writeln(title);
    buf.writeln('');
    for (final key in order) {
      final groupItems = groups[key]!;
      final t = _clubbedGroupTitle(groupItems);
      final n = groupItems.length;
      buf.writeln(n <= 1 ? '• $t' : '• $t ×$n');
    }
    return buf.toString().trimRight();
  }

  /// Groups output by recipe source (manual items in "Other items").
  static String formatPerRecipe(
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

    String groupKey(GroceryItem item) {
      final rid = item.sourceRecipeId?.trim() ?? '';
      if (rid.isNotEmpty) return 'id:$rid';
      final rname = item.sourceRecipeName?.trim() ?? '';
      if (rname.isNotEmpty) return 'name:$rname';
      return '__manual__';
    }

    final groups = <String, List<GroceryItem>>{};
    final order = <String>[];
    for (final item in filtered) {
      final k = groupKey(item);
      groups.putIfAbsent(k, () {
        order.add(k);
        return <GroceryItem>[];
      }).add(item);
    }
    if (order.remove('__manual__')) order.add('__manual__');

    String heading(String key, List<GroceryItem> groupItems) {
      if (key == '__manual__') return 'Other items';
      final name = groupItems.first.sourceRecipeName?.trim();
      if (name != null && name.isNotEmpty) return name;
      return 'Recipe';
    }

    final buf = StringBuffer();
    buf.writeln(title);
    buf.writeln('');
    for (final key in order) {
      final groupItems = groups[key]!;
      buf.writeln(heading(key, groupItems));
      for (final item in groupItems) {
        buf.writeln(formatLine(item));
      }
      buf.writeln('');
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

  static String _clubbedGroupTitle(List<GroceryItem> groupItems) {
    if (groupItems.isEmpty) return 'Item';
    // Use the shortest clean title among the group (tends to pick "Garlic"
    // over "Minced Garlic" etc.).
    final titles = groupItems
        .map((e) => GroceryIngredientDisplay.listTitle(e.name).trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (titles.isEmpty) return GroceryIngredientDisplay.listTitle(groupItems.first.name);
    titles.sort((a, b) => a.length.compareTo(b.length));
    return titles.first;
  }
}
