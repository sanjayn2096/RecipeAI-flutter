import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color kOnboardingSelectedGreen = Color(0xFF2E7D32);

/// Selectable chip with scale + color animation.
class AnimatedPreferenceChip extends StatelessWidget {
  const AnimatedPreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: enabled
              ? (_) {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          showCheckmark: false,
          selectedColor: kOnboardingSelectedGreen.withValues(alpha: 0.22),
          checkmarkColor: kOnboardingSelectedGreen,
          side: BorderSide(
            color: selected ? kOnboardingSelectedGreen : scheme.outline,
            width: selected ? 1.5 : 1,
          ),
          labelStyle: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? kOnboardingSelectedGreen : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
