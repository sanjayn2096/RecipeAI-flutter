import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    final assetPath = IngredientIconResolver.resolveAssetFor(ingredientName);
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      placeholderBuilder: (_) => SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.inventory_2_outlined, size: size, color: iconColor),
      ),
    );
  }
}
