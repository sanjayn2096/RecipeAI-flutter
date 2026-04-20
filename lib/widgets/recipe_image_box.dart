import 'package:flutter/material.dart';

/// Recipe image placeholder (remote image URLs intentionally ignored).
class RecipeImageBox extends StatelessWidget {
  const RecipeImageBox({
    super.key,
    required this.imageUrl,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final String imageUrl;
  final double? height;
  final double width;
  final BoxFit fit;
  final BorderRadius borderRadius;

  static const String _placeholder = 'assets/recipe_placeholder.png';

  @override
  Widget build(BuildContext context) {
    // Keep the input for API compatibility, but always render local placeholder art.
    final child = Image.asset(
      _placeholder,
      height: height,
      width: width == double.infinity ? null : width,
      fit: fit,
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: width == double.infinity
          ? SizedBox(
              width: double.infinity,
              height: height,
              child: child,
            )
          : child,
    );
  }
}
