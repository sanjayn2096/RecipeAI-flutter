import 'package:flutter/material.dart';

/// Recipe image: [Image.network] when [imageUrl] is http(s), else local placeholder.
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

  bool get _useNetwork {
    final t = imageUrl.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (width == double.infinity) {
      return LayoutBuilder(
        builder: (context, constraints) {
          var w = constraints.maxWidth;
          if (!w.isFinite || w <= 0) {
            w = MediaQuery.sizeOf(context).width;
          }
          return ClipRRect(
            borderRadius: borderRadius,
            child: _buildInner(context, widthPx: w),
          );
        },
      );
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: _buildInner(context, widthPx: width),
    );
  }

  Widget _buildInner(BuildContext context, {required double widthPx}) {
    if (_useNetwork) {
      final url = imageUrl.trim();
      return SizedBox(
        width: widthPx,
        height: height,
        child: Image.network(
          url,
          width: widthPx,
          height: height,
          fit: fit,
          alignment: Alignment.center,
          loadingBuilder: (context, imageChild, progress) {
            if (progress == null) return imageChild;
            return ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _placeholderChild(widthPx),
        ),
      );
    }
    return SizedBox(
      width: widthPx,
      height: height,
      child: _placeholderChild(widthPx),
    );
  }

  Widget _placeholderChild(double widthPx) {
    return Image.asset(
      _placeholder,
      height: height,
      width: widthPx,
      fit: fit,
      alignment: Alignment.center,
    );
  }
}
