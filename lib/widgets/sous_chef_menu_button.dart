import 'package:flutter/material.dart';

/// Hamburger control matching the Home app bar: solid [ColorScheme.primary] tile + [onPrimary] icon.
class SousChefMenuButton extends StatelessWidget {
  const SousChefMenuButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final child = Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.menu, color: scheme.onPrimary, size: 22),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return child;
    }
    return Tooltip(message: tooltip!, child: child);
  }
}
