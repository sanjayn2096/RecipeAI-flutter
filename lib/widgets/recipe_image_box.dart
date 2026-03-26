import 'package:flutter/material.dart';

/// Recipe image from network with local placeholder when URL is missing or fails to load.
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
    final url = imageUrl.trim();
    Widget child;
    if (url.isEmpty) {
      child = Image.asset(
        _placeholder,
        height: height,
        width: width == double.infinity ? null : width,
        fit: fit,
      );
    } else {
      child = Image.network(
        url,
        height: height,
        width: width == double.infinity ? null : width,
        fit: fit,
        errorBuilder: (_, __, ___) => Image.asset(
          _placeholder,
          height: height,
          width: width == double.infinity ? null : width,
          fit: fit,
        ),
      );
    }
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
