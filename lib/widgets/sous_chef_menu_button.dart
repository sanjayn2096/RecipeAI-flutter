import 'package:flutter/material.dart';

/// Opens the shell app drawer via a standard Material 3 [IconButton] (bar foreground).
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
    final message = tooltip;
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.menu),
      tooltip: (message != null && message.isNotEmpty) ? message : null,
      iconSize: 22,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
      ),
    );
  }
}
