import 'package:flutter/material.dart';

/// Outlined card with a thin black stroke (no shadow).
class CartoonOutlinedCard extends StatelessWidget {
  const CartoonOutlinedCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.borderRadius = 14,
    this.borderWidth = 1.5,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double borderWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      margin: margin,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.black, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
