import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// One spotlight step: measure [targetKey] after layout; optional [tabIndex] to select shell tab first.
class CoachTourStep {
  const CoachTourStep({
    required this.targetKey,
    required this.title,
    required this.body,
    this.tabIndex,
  });

  final GlobalKey targetKey;
  final String title;
  final String body;

  /// When not null, shell switches to this tab before showing the step.
  final int? tabIndex;
}

/// Drives an in-app coach-mark tour (see [CoachMarkOverlay]).
class CoachTourController extends ChangeNotifier {
  CoachTourController({required List<CoachTourStep> steps}) : _steps = steps;

  final List<CoachTourStep> _steps;
  bool _active = false;
  int _index = 0;

  List<CoachTourStep> get steps => _steps;
  bool get isActive => _active;
  int get currentIndex => _index;
  CoachTourStep? get currentStep =>
      _active && _index >= 0 && _index < _steps.length ? _steps[_index] : null;
  bool get isLastStep => _active && _index == _steps.length - 1;

  void start() {
    _active = true;
    _index = 0;
    notifyListeners();
  }

  void next() {
    if (!_active) return;
    if (_index + 1 >= _steps.length) {
      finish();
      return;
    }
    _index++;
    notifyListeners();
  }

  void previous() {
    if (!_active || _index <= 0) return;
    _index--;
    notifyListeners();
  }

  void skip() => finish();

  void finish() {
    _active = false;
    _index = 0;
    notifyListeners();
  }
}

/// Full-screen dim + rounded hole + tooltip. Blocks interaction except controls.
class CoachMarkOverlay extends StatefulWidget {
  const CoachMarkOverlay({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final CoachTourController controller;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  State<CoachMarkOverlay> createState() => _CoachMarkOverlayState();
}

class _CoachMarkOverlayState extends State<CoachMarkOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Rect? _holeRectFor(CoachTourStep step) {
    final ctx = step.targetKey.currentContext;
    final ro = ctx?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.controller.currentStep;
    if (step == null) return const SizedBox.shrink();

    final hole = _holeRectFor(step);
    if (hole == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    final size = MediaQuery.sizeOf(context);
    const padding = 8.0;

    final cardMaxWidth = math.min(size.width - 32, 400.0);
    final stepIndex = widget.controller.currentIndex;
    final stepCount = widget.controller.steps.length;

    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CoachHolePainter(
                hole: hole,
                padding: padding,
                scrim: const Color(0x99000000),
              ),
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
            ),
          ),
          if (hole != null)
            _TooltipCard(
              hole: hole,
              padding: padding,
              screenSize: size,
              maxWidth: cardMaxWidth,
              title: step.title,
              body: step.body,
              stepLabel: '${stepIndex + 1} / $stepCount',
              onNext: widget.onNext,
              onBack: stepIndex > 0 ? widget.onBack : null,
              onSkip: widget.onSkip,
              isLast: widget.controller.isLastStep,
            ),
        ],
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.hole,
    required this.padding,
    required this.screenSize,
    required this.maxWidth,
    required this.title,
    required this.body,
    required this.stepLabel,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    required this.isLast,
  });

  final Rect hole;
  final double padding;
  final Size screenSize;
  final double maxWidth;
  final String title;
  final String body;
  final String stepLabel;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final inset = hole.inflate(padding);
    const gap = 12.0;
    final safe = MediaQuery.paddingOf(context);

    double top;
    const estimatedCardHeight = 220.0;
    final spaceBelow = screenSize.height - inset.bottom - gap - safe.bottom;
    final spaceAbove = inset.top - gap - safe.top;

    if (spaceBelow >= estimatedCardHeight || spaceBelow >= spaceAbove) {
      top = (inset.bottom + gap).clamp(
        safe.top + gap,
        screenSize.height - estimatedCardHeight - safe.bottom,
      );
    } else {
      top = (inset.top - gap - estimatedCardHeight).clamp(
        safe.top + gap,
        screenSize.height - estimatedCardHeight - safe.bottom,
      );
    }

    return Positioned(
      left: 16,
      right: 16,
      top: top,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    stepLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onSkip,
                        child: const Text(AppStrings.skip),
                      ),
                      const Spacer(),
                      if (onBack != null)
                        TextButton(
                          onPressed: onBack,
                          child: const Text(AppStrings.back),
                        ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: onNext,
                        child: Text(isLast ? AppStrings.ok : AppStrings.next),
                      ),
                    ],
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

class _CoachHolePainter extends CustomPainter {
  _CoachHolePainter({
    required this.hole,
    required this.padding,
    required this.scrim,
  });

  final Rect? hole;
  final double padding;
  final Color scrim;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    if (hole == null || hole!.isEmpty) {
      canvas.drawPath(full, Paint()..color = scrim);
      return;
    }
    final inset = hole!.inflate(padding);
    final cut = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          inset.intersect(Rect.fromLTWH(0, 0, size.width, size.height)),
          const Radius.circular(12),
        ),
      );
    final overlay = Path.combine(PathOperation.difference, full, cut);
    canvas.drawPath(overlay, Paint()..color = scrim);
  }

  @override
  bool shouldRepaint(covariant _CoachHolePainter oldDelegate) {
    return oldDelegate.hole != hole ||
        oldDelegate.padding != padding ||
        oldDelegate.scrim != scrim;
  }
}
