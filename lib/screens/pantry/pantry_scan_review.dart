import 'package:flutter/material.dart';

import '../../core/l10n_context.dart';
import '../../services/pantry/pantry_scan_suggestion.dart';
import 'pantry_captured_photo.dart';

/// Tracks user selection for one grouped suggestion.
class PantrySuggestionSelection {
  PantrySuggestionSelection({
    required this.suggestion,
    String? selectedName,
  }) : selectedName = selectedName ?? suggestion.primaryName;

  final PantryScanSuggestion suggestion;
  String selectedName;

  String get quantity => suggestion.quantity;
  String get unit => suggestion.unit;
}

/// Photo preview + per-item accept (pantry) / edit / dismiss actions.
class PantryScanReview extends StatelessWidget {
  const PantryScanReview({
    super.key,
    required this.photo,
    required this.selections,
    required this.onSelectedNameChanged,
    required this.onAcceptItem,
    required this.onEditItem,
    required this.onDismissItem,
    required this.onScanAgain,
  });

  final PantryCapturedPhoto photo;
  final List<PantrySuggestionSelection> selections;
  final void Function(int groupIndex, String name) onSelectedNameChanged;
  final void Function(int index) onAcceptItem;
  final void Function(int index) onEditItem;
  final void Function(int index) onDismissItem;
  final VoidCallback onScanAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CapturedPhotoPreview(photo: photo),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: selections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _SuggestionGroupCard(
                selection: selections[index],
                onNameSelected: (name) => onSelectedNameChanged(index, name),
                onAccept: () => onAcceptItem(index),
                onEdit: () => onEditItem(index),
                onDismiss: () => onDismissItem(index),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onScanAgain,
          child: Text(context.l10n.groceryPantryScanScanAgain),
        ),
      ],
    );
  }
}

class _CapturedPhotoPreview extends StatelessWidget {
  const _CapturedPhotoPreview({required this.photo});

  final PantryCapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.memory(
            photo.bytes,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(ctx.l10n.groceryPantryScanTitle),
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.memory(photo.bytes, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionGroupCard extends StatelessWidget {
  const _SuggestionGroupCard({
    required this.selection,
    required this.onNameSelected,
    required this.onAccept,
    required this.onEdit,
    required this.onDismiss,
  });

  final PantrySuggestionSelection selection;
  final ValueChanged<String> onNameSelected;
  final VoidCallback onAccept;
  final VoidCallback onEdit;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = selection.suggestion;
    final sizeLabel = _formatSize(suggestion.quantity, suggestion.unit);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.groceryPantryScanLooksLike,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selection.selectedName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sizeLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          sizeLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.groceryPantryScanAcceptTooltip,
                  icon: Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: onAccept,
                ),
                IconButton(
                  tooltip: context.l10n.groceryPantryScanEditTooltip,
                  icon: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _showEditMenu(context),
                ),
              ],
            ),
            if (suggestion.alternates.isNotEmpty) ...[
              const SizedBox(height: 4),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                title: Text(
                  context.l10n.groceryPantryScanOtherPossibilities,
                  style: theme.textTheme.titleSmall,
                ),
                initiallyExpanded: false,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestion.allNames.map(
                      (name) {
                        final selected = name == selection.selectedName;
                        return ChoiceChip(
                          label: Text(name),
                          selected: selected,
                          onSelected: (_) => onNameSelected(name),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.groceryPantryScanEditItem),
              onTap: () {
                Navigator.of(ctx).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.close,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                context.l10n.groceryPantryScanDismissItem,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                onDismiss();
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _formatSize(String quantity, String unit) {
    final q = quantity.trim();
    final u = unit.trim();
    if (q.isEmpty && u.isEmpty) return null;
    return [q, u].where((s) => s.isNotEmpty).join(' ');
  }
}
