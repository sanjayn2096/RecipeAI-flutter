import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../core/l10n_context.dart';
import '../core/grocery_ingredient_display.dart';
import '../core/grocery_ingredient_normalize.dart';
import '../core/grocery_list_text_export.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/grocery_item.dart';
import '../view_models/grocery_list_view_model.dart';
import '../widgets/grocery_item_editor_dialog.dart';
import '../widgets/ingredient_icon.dart';

/// Shopping list: edit, check off, multi-select delete, share, copy.
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

enum _GroceryIngredientsViewMode {
  allClubbed,
  perRecipe,
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  _GroceryIngredientsViewMode _viewMode = _GroceryIngredientsViewMode.allClubbed;
  bool _selecting = false;
  final Set<String> _selectedIds = {};

  void _enterSelectMode([String? initialId]) {
    setState(() {
      _selecting = true;
      _selectedIds.clear();
      if (initialId != null) _selectedIds.add(initialId);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selecting = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<GroceryItem> items) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(items.map((e) => e.id));
    });
  }

  void _deselectAll() {
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.groceryListViewModel,
      builder: (context, _) {
        final vm = widget.groceryListViewModel;
        final items = vm.items;
        final canShare = items.isNotEmpty && !_selecting;

        if (_selecting && items.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selecting) _exitSelectMode();
          });
        }

        final listBody = !vm.ready
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.groceryEmptyHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                : (_viewMode == _GroceryIngredientsViewMode.allClubbed
                    ? _buildAllClubbedList(context, vm, items)
                    : _buildPerRecipeGroupedList(context, vm, items));

        final fab = _selecting
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _addItem(context, vm),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.groceryAddItem),
              );

        if (widget.embedInShell) {
          return Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _actionRow(context, vm, canShare),
                  ),
                ),
                _viewToggle(context, enabled: items.isNotEmpty && !_selecting),
                Expanded(child: listBody),
              ],
            ),
            floatingActionButton: fab,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _selecting
                  ? context.l10n.groceryDeleteSelected(_selectedIds.length)
                  : context.l10n.groceryListTitle,
            ),
            leading: _selecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: context.l10n.groceryCancelSelection,
                    onPressed: _exitSelectMode,
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
            actions: _selecting
                ? _selectModeActions(context, vm, items)
                : _normalAppBarActions(context, vm, items, canShare),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _viewToggle(context, enabled: items.isNotEmpty && !_selecting),
              Expanded(child: listBody),
            ],
          ),
          floatingActionButton: fab,
        );
      },
    );
  }

  List<Widget> _selectModeActions(
    BuildContext context,
    GroceryListViewModel vm,
    List<GroceryItem> items,
  ) {
    final allSelected =
        items.isNotEmpty && _selectedIds.length == items.length;
    return [
      TextButton(
        onPressed: items.isEmpty
            ? null
            : () {
                if (allSelected) {
                  _deselectAll();
                } else {
                  _selectAll(items);
                }
              },
        child: Text(
          allSelected
              ? context.l10n.groceryDeselectAll
              : context.l10n.grocerySelectAll,
        ),
      ),
      TextButton(
        onPressed: _selectedIds.isEmpty
            ? null
            : () => _confirmDeleteSelected(context, vm),
        child: Text(context.l10n.groceryDeleteSelected(_selectedIds.length)),
      ),
    ];
  }

  List<Widget> _normalAppBarActions(
    BuildContext context,
    GroceryListViewModel vm,
    List<GroceryItem> items,
    bool canShare,
  ) {
    return [
      if (items.any((e) => e.isChecked))
        TextButton(
          onPressed: () async {
            await vm.clearCheckedItems();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.groceryRemovedChecked),
                ),
              );
            }
          },
          child: Text(context.l10n.groceryClearChecked),
        ),
      if (items.isNotEmpty)
        TextButton(
          onPressed: () => _enterSelectMode(),
          child: Text(context.l10n.grocerySelect),
        ),
      IconButton(
        tooltip: context.l10n.groceryCopyList,
        icon: const Icon(Icons.copy_outlined),
        onPressed: !canShare
            ? null
            : () => _copy(context, vm, onlyUnchecked: false),
      ),
      IconButton(
        tooltip: context.l10n.groceryShareList,
        icon: const Icon(Icons.share_outlined),
        onPressed: !canShare
            ? null
            : () => _share(context, vm, onlyUnchecked: false),
      ),
      PopupMenuButton<String>(
        enabled: canShare,
        icon: const Icon(Icons.more_vert),
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'clear_all',
            child: Text(context.l10n.groceryClearAll),
          ),
          PopupMenuItem(
            value: 'share_need',
            child: Text(context.l10n.groceryShareStillNeed),
          ),
          PopupMenuItem(
            value: 'copy_need',
            child: Text(context.l10n.groceryCopyStillNeed),
          ),
        ],
        onSelected: (v) async {
          if (v == 'clear_all') {
            await _confirmClearAll(context, vm);
          } else if (v == 'share_need') {
            await _share(context, vm, onlyUnchecked: true);
          } else if (v == 'copy_need') {
            await _copy(context, vm, onlyUnchecked: true);
          }
        },
      ),
    ];
  }

  Widget _viewToggle(BuildContext context, {required bool enabled}) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: SegmentedButton<_GroceryIngredientsViewMode>(
          segments: [
            ButtonSegment(
              value: _GroceryIngredientsViewMode.allClubbed,
              label: Text(context.l10n.groceryViewAllIngredients),
            ),
            ButtonSegment(
              value: _GroceryIngredientsViewMode.perRecipe,
              label: Text(context.l10n.groceryViewPerRecipe),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: !enabled
              ? null
              : (s) => setState(() => _viewMode = s.first),
        ),
      ),
    );
  }

  Widget _buildPerRecipeGroupedList(
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
        final heading = _groupTitle(context, key, groupItems);
        return ExpansionTile(
          key: PageStorageKey<String>(key),
          title: Text(
            heading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          initiallyExpanded: _selecting,
          children: [
            for (final item in groupItems) _itemRow(context, vm, item),
          ],
        );
      },
    );
  }

  Widget _buildAllClubbedList(
    BuildContext context,
    GroceryListViewModel vm,
    List<GroceryItem> items,
  ) {
    final groups = <String, List<GroceryItem>>{};
    for (final item in items) {
      final k = GroceryIngredientDisplay.baseIngredientKey(item.name);
      groups.putIfAbsent(k, () => []).add(item);
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        final ta = GroceryIngredientDisplay.listTitle(groups[a]!.first.name);
        final tb = GroceryIngredientDisplay.listTitle(groups[b]!.first.name);
        return ta.toLowerCase().compareTo(tb.toLowerCase());
      });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: keys.length,
      itemBuilder: (context, i) {
        final key = keys[i];
        final groupItems = groups[key]!;
        final title = GroceryIngredientDisplay.listTitle(groupItems.first.name);
        final total = groupItems.length;
        final unchecked = groupItems.where((e) => !e.isChecked).length;
        final recipeCount = groupItems
            .map((e) => (e.sourceRecipeId ?? e.sourceRecipeName ?? '').trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .length;

        final subtitleParts = <String>[];
        if (recipeCount > 0) {
          subtitleParts
              .add(recipeCount == 1 ? '1 recipe' : '$recipeCount recipes');
        }
        if (unchecked != total) {
          subtitleParts.add('$unchecked left');
        }

        return ExpansionTile(
          key: PageStorageKey<String>('club:$key'),
          title: Text(
            total <= 1 ? title : '$title ×$total',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
          initiallyExpanded: _selecting,
          children: [
            for (final item in groupItems) _itemRow(context, vm, item),
          ],
        );
      },
    );
  }

  Widget _itemRow(
    BuildContext context,
    GroceryListViewModel vm,
    GroceryItem item,
  ) {
    final title = Row(
      children: [
        IngredientIcon(
          ingredientName: item.name,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            GroceryIngredientDisplay.listTitle(item.name),
          ),
        ),
      ],
    );

    if (_selecting) {
      return CheckboxListTile(
        value: _selectedIds.contains(item.id),
        onChanged: (_) => _toggleSelected(item.id),
        title: title,
        subtitle: _rowSubtitle(context, item),
      );
    }

    return Dismissible(
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
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.selectionClick();
          _enterSelectMode(item.id);
        },
        child: CheckboxListTile(
          value: item.isChecked,
          onChanged: (v) {
            if (v != null) vm.setChecked(item.id, v);
          },
          title: title,
          subtitle: _rowSubtitle(context, item),
          secondary: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editItem(context, vm, item),
          ),
        ),
      ),
    );
  }

  Widget _actionRow(
    BuildContext context,
    GroceryListViewModel vm,
    bool canShare,
  ) {
    final items = vm.items;
    if (_selecting) {
      final allSelected =
          items.isNotEmpty && _selectedIds.length == items.length;
      return Wrap(
        alignment: WrapAlignment.end,
        spacing: 4,
        children: [
          TextButton(
            onPressed: _exitSelectMode,
            child: Text(context.l10n.groceryCancelSelection),
          ),
          TextButton(
            onPressed: items.isEmpty
                ? null
                : () {
                    if (allSelected) {
                      _deselectAll();
                    } else {
                      _selectAll(items);
                    }
                  },
            child: Text(
              allSelected
                  ? context.l10n.groceryDeselectAll
                  : context.l10n.grocerySelectAll,
            ),
          ),
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _confirmDeleteSelected(context, vm),
            child:
                Text(context.l10n.groceryDeleteSelected(_selectedIds.length)),
          ),
        ],
      );
    }

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
                  SnackBar(
                    content: Text(context.l10n.groceryRemovedChecked),
                  ),
                );
              }
            },
            child: Text(context.l10n.groceryClearChecked),
          ),
        if (items.isNotEmpty)
          TextButton(
            onPressed: () => _enterSelectMode(),
            child: Text(context.l10n.grocerySelect),
          ),
        IconButton(
          tooltip: context.l10n.groceryCopyList,
          icon: const Icon(Icons.copy_outlined),
          onPressed:
              !canShare ? null : () => _copy(context, vm, onlyUnchecked: false),
        ),
        IconButton(
          tooltip: context.l10n.groceryShareList,
          icon: const Icon(Icons.share_outlined),
          onPressed: !canShare
              ? null
              : () => _share(context, vm, onlyUnchecked: false),
        ),
        PopupMenuButton<String>(
          enabled: canShare,
          icon: const Icon(Icons.more_vert),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'clear_all',
              child: Text(context.l10n.groceryClearAll),
            ),
            PopupMenuItem(
              value: 'share_need',
              child: Text(context.l10n.groceryShareStillNeed),
            ),
            PopupMenuItem(
              value: 'copy_need',
              child: Text(context.l10n.groceryCopyStillNeed),
            ),
          ],
          onSelected: (v) async {
            if (v == 'clear_all') {
              await _confirmClearAll(context, vm);
            } else if (v == 'share_need') {
              await _share(context, vm, onlyUnchecked: true);
            } else if (v == 'copy_need') {
              await _copy(context, vm, onlyUnchecked: true);
            }
          },
        ),
      ],
    );
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    GroceryListViewModel vm,
  ) async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groceryDeleteSelectedTitle),
        content: Text(context.l10n.groceryDeleteSelectedBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.groceryCancelSelection),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(context.l10n.groceryDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ids = List<String>.from(_selectedIds);
    await vm.deleteItems(ids);
    if (!context.mounted) return;
    _exitSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.groceryRemovedSelected(count))),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    GroceryListViewModel vm,
  ) async {
    if (vm.items.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.groceryClearAllTitle),
        content: Text(context.l10n.groceryClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.groceryCancelSelection),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(context.l10n.groceryClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await vm.clearAllItems();
    if (!context.mounted) return;
    if (_selecting) _exitSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.groceryClearedAll)),
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
    if (item.sourceRecipeId != null && item.sourceRecipeId!.trim().isNotEmpty) {
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

  String _groupTitle(
    BuildContext context,
    String key,
    List<GroceryItem> groupItems,
  ) {
    if (key == '__manual__') {
      return context.l10n.groceryGroupOther;
    }
    final name = groupItems.first.sourceRecipeName?.trim();
    if (name != null && name.isNotEmpty) {
      return context.l10n.groceryIngredientsForRecipe(name);
    }
    return context.l10n.groceryGroupUnnamedRecipe;
  }

  Future<void> _share(
    BuildContext context,
    GroceryListViewModel vm, {
    required bool onlyUnchecked,
  }) async {
    final l10n = context.l10n;
    if (onlyUnchecked && !vm.items.any((e) => !e.isChecked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groceryNothingLeftToBuy)),
      );
      return;
    }
    final text = _viewMode == _GroceryIngredientsViewMode.perRecipe
        ? GroceryListTextExport.formatPerRecipe(
            vm.items,
            title: l10n.groceryShareSubject,
            onlyUnchecked: onlyUnchecked,
          )
        : GroceryListTextExport.formatAllClubbed(
            vm.items,
            title: l10n.groceryShareSubject,
            onlyUnchecked: onlyUnchecked,
          );
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryShare,
      action: [
        _viewMode == _GroceryIngredientsViewMode.perRecipe
            ? 'per_recipe'
            : 'all_clubbed',
        onlyUnchecked ? 'unchecked_only' : 'all',
      ].join('_'),
    );
    await Share.share(text, subject: l10n.groceryShareSubject);
  }

  Future<void> _copy(
    BuildContext context,
    GroceryListViewModel vm, {
    required bool onlyUnchecked,
  }) async {
    if (onlyUnchecked && !vm.items.any((e) => !e.isChecked)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groceryNothingLeftToBuy)),
      );
      return;
    }
    final text = _viewMode == _GroceryIngredientsViewMode.perRecipe
        ? GroceryListTextExport.formatPerRecipe(
            vm.items,
            title: context.l10n.groceryShareSubject,
            onlyUnchecked: onlyUnchecked,
          )
        : GroceryListTextExport.formatAllClubbed(
            vm.items,
            title: context.l10n.groceryShareSubject,
            onlyUnchecked: onlyUnchecked,
          );
    await Clipboard.setData(ClipboardData(text: text));
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryCopy,
      action: [
        _viewMode == _GroceryIngredientsViewMode.perRecipe
            ? 'per_recipe'
            : 'all_clubbed',
        onlyUnchecked ? 'unchecked_only' : 'all',
      ].join('_'),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groceryCopied)),
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
