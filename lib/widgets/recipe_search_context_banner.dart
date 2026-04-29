import 'package:flutter/material.dart';

import '../core/recipe_search_context.dart';
import '../services/session_manager.dart';

/// Collapsible summary above the recipe list explaining generation inputs.
class RecipeSearchContextBanner extends StatelessWidget {
  const RecipeSearchContextBanner({
    super.key,
    required this.sessionManager,
    required this.onChangeSearchSettings,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final SessionManager sessionManager;
  final VoidCallback onChangeSearchSettings;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final ctx = RecipeSearchContext.fromSession(sessionManager);
    final scheme = Theme.of(context).colorScheme;

    Widget chip(String label, {Color? tint}) {
      return Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        backgroundColor:
            tint ?? scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      );
    }

    final note = ctx.allergyNotes;
    final bullets = ctx.detailLines
        .map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: scheme.primary)),
                Expanded(child: Text(s, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        )
        .toList();

    return Padding(
      padding: margin,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            'Why these recipes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                ctx.headline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
              ),
            ),
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bullets,
            ],
            if (ctx.ingredientLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pantry / ingredients sent',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ctx.ingredientLabels
                    .map((e) => chip(e))
                    .toList(),
              ),
            ],
            if (ctx.dietProfileLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Diet profiles',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    ctx.dietProfileLabels.map((e) => chip(e)).toList(),
              ),
            ],
            if (ctx.allergenLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Avoiding',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ctx.allergenLabels.map((e) {
                  return chip(
                    e,
                    tint:
                        scheme.errorContainer.withValues(alpha: 0.35),
                  );
                }).toList(),
              ),
            ],
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Allergy notes',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note.length > 260 ? '${note.substring(0, 257)}…' : note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onChangeSearchSettings,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Change search settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
