import 'package:flutter/material.dart';

import '../core/ingredient_icon_resolver.dart';

class IngredientIcon extends StatelessWidget {
  const IngredientIcon({
    super.key,
    required this.ingredientName,
    this.size = 20,
    this.color,
  });

  final String ingredientName;
  final double size;

  /// Reserved for raster icons: theme tint would distort PNG artwork. Unused for now.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!IngredientIconResolver.hasIngredientMatch(ingredientName)) {
      return _fallbackImage(context);
    }

    final assetPath = IngredientIconResolver.resolveAssetFor(ingredientName);
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallbackImage(context),
    );
  }

  Widget _fallbackImage(BuildContext context) {
    return Image.asset(
      IngredientIconResolver.fallbackAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallbackIcon(context),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        Icons.shopping_basket_outlined,
        size: size,
        color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
