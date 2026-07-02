import 'package:flutter/material.dart';

/// Shared staggered fade/slide entrance for onboarding lists.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayPerItem = const Duration(milliseconds: 50),
    this.baseDelay = const Duration(milliseconds: 120),
  });

  final int index;
  final Widget child;
  final Duration delayPerItem;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: baseDelay + delayPerItem * index,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
