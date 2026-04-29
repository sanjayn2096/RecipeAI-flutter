import 'package:flutter/material.dart';

import '../core/nutritional_badge_signals.dart';
import '../data/models/recipe.dart';
import 'recipe_image_box.dart';

/// Rich row for recipe lists (image, title, meta, macro/diet cues, trailing actions).
class RecipeListRow extends StatelessWidget {
  const RecipeListRow({
    super.key,
    required this.recipe,
    required this.trailingActions,
    this.onTap,
    this.miniImageSize = 64,
    this.heroWidth,
    this.metaExtra,
  });

  final Recipe recipe;
  final List<Widget> trailingActions;
  final VoidCallback? onTap;
  final double miniImageSize;
  final double? heroWidth;

  /// Shown after cuisine / cook time when non-empty (e.g. trending favorite count).
  final String? metaExtra;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final macros = MacroBadgeSignals.fromNutritional(recipe.nutritionalValue);
    final metaBits = <String>[
      if (recipe.cuisine.trim().isNotEmpty) recipe.cuisine,
      if (recipe.cookingTime.trim().isNotEmpty) recipe.cookingTime,
      if (metaExtra != null && metaExtra!.trim().isNotEmpty) metaExtra!.trim(),
    ];
    final meta = metaBits.join(' · ');

    Widget badgeIcon({
      required IconData icon,
      required String tooltip,
      required Color color,
    }) {
      return Tooltip(
        message: tooltip,
        child: Semantics(
          label: tooltip,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
    }

    final badges = <Widget>[];
    if (macros.proteinRich) {
      badges.add(
        badgeIcon(
          icon: Icons.fitness_center_rounded,
          tooltip: 'Protein-forward',
          color: scheme.tertiary,
        ),
      );
    }
    if (macros.carbRich) {
      badges.add(
        badgeIcon(
          icon: Icons.ramen_dining_rounded,
          tooltip: 'Carb‑forward',
          color: scheme.secondary,
        ),
      );
    }
    if (recipe.vegetarianFriendly == true) {
      badges.add(
        badgeIcon(
          icon: Icons.eco_rounded,
          tooltip: 'Vegetarian‑friendly',
          color: Colors.green.shade700,
        ),
      );
    }
    if (recipe.glutenFriendly == true) {
      badges.add(
        badgeIcon(
          icon: Icons.health_and_safety_rounded,
          tooltip: 'Gluten‑friendly (no wheat, barley, or rye)',
          color: scheme.primary,
        ),
      );
    }

    final lead = SizedBox(
      height: miniImageSize,
      width: miniImageSize,
      child: RecipeImageBox(
        imageUrl: recipe.image,
        height: miniImageSize,
        width: heroWidth ?? miniImageSize,
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.recipeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(children: badges),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: trailingActions,
            ),
          ],
        ),
      ),
    );
  }
}
