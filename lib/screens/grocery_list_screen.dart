import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_strings.dart';
import '../core/grocery_ingredient_display.dart';
import '../core/grocery_ingredient_normalize.dart';
import '../core/grocery_list_text_export.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/grocery_item.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/grocery_item_editor_dialog.dart';

/// Shopping list: edit, check off, share, copy.
///
/// When [embedInShell] is true, omit the [AppBar] and back button — used inside
/// [HomeShellScreen] where the shell provides the app bar.
class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({
    super.key,
    required this.groceryListViewModel,
    required this.appTelemetry,
    this.embedInShell = false,
  });

  final GroceryListViewModel groceryListViewModel;
  final AppTelemetry appTelemetry;

  /// No top [AppBar]; shell provides title and global actions.
  final bool embedInShell;

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.groceryListViewModel,
      builder: (context, _) {
        final vm = widget.groceryListViewModel;
        final items = vm.items;
        final canShare = items.isNotEmpty;

        final listBody = !vm.ready
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppStrings.groceryEmptyHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : _buildGroupedList(context, vm, items);

        final fab = FloatingActionButton.extended(
          onPressed: () => _addItem(context, vm),
          icon: const Icon(Icons.add),
          label: const Text(AppStrings.groceryAddItem),
        );

        if (widget.embedInShell) {
          return Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _actionRow(context, vm, canShare),
                  ),
                ),
                Expanded(child: listBody),
              ],
            ),
            floatingActionButton: fab,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.groceryListTitle),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (items.any((e) => e.isChecked))
                TextButton(
                  onPressed: () async {
                    await vm.clearCheckedItems();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.groceryRemovedChecked),
                        ),
                      );
                    }
                  },
                  child: const Text(AppStrings.groceryClearChecked),
                ),
              IconButton(
                tooltip: AppStrings.groceryCopyList,
                icon: const Icon(Icons.copy_outlined),
                onPressed: !canShare
                    ? null
                    : () => _copy(context, vm, onlyUnchecked: false),
              ),
              IconButton(
                tooltip: AppStrings.groceryShareList,
                icon: const Icon(Icons.share_outlined),
                onPressed: !canShare
                    ? null
                    : () => _share(context, vm, onlyUnchecked: false),
              ),
              PopupMenuButton<String>(
                enabled: canShare,
                icon: const Icon(Icons.more_vert),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'share_need',
                    child: Text(AppStrings.groceryShareStillNeed),
                  ),
                  const PopupMenuItem(
                    value: 'copy_need',
                    child: Text(AppStrings.groceryCopyStillNeed),
                  ),
                ],
                onSelected: (v) async {
                  if (v == 'share_need') {
                    await _share(context, vm, onlyUnchecked: true);
                  } else if (v == 'copy_need') {
                    await _copy(context, vm, onlyUnchecked: true);
                  }
                },
              ),
            ],
          ),
          body: listBody,
          floatingActionButton: fab,
        );
      },
    );
  }

  Widget _buildGroupedList(
    BuildContext context,
    GroceryListViewModel vm,
    List<GroceryItem> items,
  ) {
    final order = _groupKeyOrder(items);
    final groups = _groupMap(items);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: order.length,
      itemBuilder: (context, gi) {
        final key = order[gi];
        final groupItems = groups[key]!;
        final heading = _groupTitle(key, groupItems);
        return ExpansionTile(
          key: PageStorageKey<String>(key),
          title: Text(
            heading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          initiallyExpanded: false,
          children: [
            for (final item in groupItems)
              Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                onDismissed: (_) => vm.deleteItem(item.id),
                child: CheckboxListTile(
                  value: item.isChecked,
                  onChanged: (v) {
                    if (v != null) vm.setChecked(item.id, v);
                  },
                  title: Text(
                    GroceryIngredientDisplay.listTitle(item.name),
                  ),
                  subtitle: _rowSubtitle(context, item),
                  secondary: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editItem(context, vm, item),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _actionRow(
    BuildContext context,
    GroceryListViewModel vm,
    bool canShare,
  ) {
    final items = vm.items;
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      children: [
        if (items.any((e) => e.isChecked))
          TextButton(
            onPressed: () async {
              await vm.clearCheckedItems();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(AppStrings.groceryRemovedChecked),
                  ),
                );
              }
            },
            child: const Text(AppStrings.groceryClearChecked),
          ),
        IconButton(
          tooltip: AppStrings.groceryCopyList,
          icon: const Icon(Icons.copy_outlined),
          onPressed:
              !canShare ? null : () => _copy(context, vm, onlyUnchecked: false),
        ),
        IconButton(
          tooltip: AppStrings.groceryShareList,
          icon: const Icon(Icons.share_outlined),
          onPressed:
              !canShare ? null : () => _share(context, vm, onlyUnchecked: false),
        ),
        PopupMenuButton<String>(
          enabled: canShare,
          icon: const Icon(Icons.more_vert),
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'share_need',
              child: Text(AppStrings.groceryShareStillNeed),
            ),
            const PopupMenuItem(
              value: 'copy_need',
              child: Text(AppStrings.groceryCopyStillNeed),
            ),
          ],
          onSelected: (v) async {
            if (v == 'share_need') {
              await _share(context, vm, onlyUnchecked: true);
            } else if (v == 'copy_need') {
              await _copy(context, vm, onlyUnchecked: true);
            }
          },
        ),
      ],
    );
  }

  Widget? _rowSubtitle(BuildContext context, GroceryItem item) {
    final qtyLine = _qtySubtitle(item);
    final note = item.note?.trim();
    if (qtyLine == null && (note == null || note.isEmpty)) return null;
    final parts = <String>[];
    if (qtyLine != null) parts.add(qtyLine);
    if (note != null && note.isNotEmpty) parts.add(note);
    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  /// Quantity line for subtitle (e.g. "1 unit", "2 kg").
  String? _qtySubtitle(GroceryItem item) {
    final q = item.quantity?.trim();
    final u = item.unit?.trim();
    final qStr = (q == null || q.isEmpty) ? '1' : q;
    if (u == null || u.isEmpty) {
      if (q == null || q.isEmpty) return null;
      return q;
    }
    if (u == GroceryIngredientNormalize.unitEach) {
      return '$qStr unit';
    }
    return '$qStr $u';
  }

  String _groupKey(GroceryItem item) {
    if (item.sourceRecipeId != null &&
        item.sourceRecipeId!.trim().isNotEmpty) {
      return 'id:${item.sourceRecipeId!.trim()}';
    }
    if (item.sourceRecipeName != null &&
        item.sourceRecipeName!.trim().isNotEmpty) {
      return 'name:${item.sourceRecipeName!.trim()}';
    }
    return '__manual__';
  }

  List<String> _groupKeyOrder(List<GroceryItem> items) {
    final order = <String>[];
    final seen = <String>{};
    for (final item in items) {
      final k = _groupKey(item);
      if (seen.add(k)) order.add(k);
    }
    if (order.remove('__manual__')) {
      order.add('__manual__');
    }
    return order;
  }

  Map<String, List<GroceryItem>> _groupMap(List<GroceryItem> items) {
    final m = <String, List<GroceryItem>>{};
    for (final item in items) {
      final k = _groupKey(item);
      m.putIfAbsent(k, () => []).add(item);
    }
    return m;
  }

  String _groupTitle(String key, List<GroceryItem> groupItems) {
    if (key == '__manual__') {
      return AppStrings.groceryGroupOther;
    }
    final name = groupItems.first.sourceRecipeName?.trim();
    if (name != null && name.isNotEmpty) {
      return AppStrings.groceryIngredientsForRecipe(name);
    }
    return AppStrings.groceryGroupUnnamedRecipe;
  }

  Future<void> _share(
    BuildContext context,
    GroceryListViewModel vm, {
    required bool onlyUnchecked,
  }) async {
    if (onlyUnchecked && !vm.items.any((e) => !e.isChecked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.groceryNothingLeftToBuy)),
      );
      return;
    }
    final text = GroceryListTextExport.formatList(
      vm.items,
      title: AppStrings.groceryShareSubject,
      onlyUnchecked: onlyUnchecked,
    );
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryShare,
      action: onlyUnchecked ? 'unchecked_only' : 'all',
    );
    await Share.share(text, subject: AppStrings.groceryShareSubject);
  }

  Future<void> _copy(
    BuildContext context,
    GroceryListViewModel vm, {
    required bool onlyUnchecked,
  }) async {
    if (onlyUnchecked && !vm.items.any((e) => !e.isChecked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.groceryNothingLeftToBuy)),
      );
      return;
    }
    final text = GroceryListTextExport.formatList(
      vm.items,
      title: AppStrings.groceryShareSubject,
      onlyUnchecked: onlyUnchecked,
    );
    await Clipboard.setData(ClipboardData(text: text));
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryCopy,
      action: onlyUnchecked ? 'unchecked_only' : 'all',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.groceryCopied)),
      );
    }
  }

  Future<void> _addItem(BuildContext context, GroceryListViewModel vm) async {
    final result = await showGroceryItemEditorDialog(
      context,
      initial: null,
      isEdit: false,
    );
    if (result != null && context.mounted) {
      await vm.addManualItem(
        name: result.name,
        quantity: result.quantity,
        unit: result.unit,
        note: result.note,
      );
    }
  }

  Future<void> _editItem(
    BuildContext context,
    GroceryListViewModel vm,
    GroceryItem item,
  ) async {
    final result = await showGroceryItemEditorDialog(
      context,
      initial: item,
      isEdit: true,
    );
    if (result != null && context.mounted) {
      await vm.updateItem(
        item.copyWith(
          name: result.name,
          quantity: result.quantity,
          unit: result.unit,
          note: result.note,
          clearNote: result.note == null,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
