import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animated_preference_chip.dart';

/// Tappable cuisine card for onboarding grid.
class AnimatedCuisineCard extends StatelessWidget {
  const AnimatedCuisineCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: selected ? 1.04 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Material(
        color: selected
            ? kOnboardingSelectedGreen.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? kOnboardingSelectedGreen : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap();
                }
              : null,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected
                              ? kOnboardingSelectedGreen
                              : scheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Emoji map for onboarding cuisine cards.
String cuisineEmojiForKey(String key) {
  switch (key) {
    case 'indian':
      return '🍛';
    case 'mexican':
      return '🌮';
    case 'chinese':
      return '🥡';
    case 'thai':
      return '🍜';
    case 'korean':
      return '🥢';
    case 'italian':
      return '🍝';
    case 'american':
      return '🍔';
    case 'surprise_me':
      return '🎲';
    default:
      return '🍽️';
  }
}
