import 'dart:async';

import 'package:flutter/material.dart';
import 'package:recipe_ai/l10n/app_localizations.dart';

import '../core/l10n_context.dart';
import '../core/l10n_extensions.dart';

/// Cycles catchy lines below the recipe-generation loading animation.
class RotatingRecipeLoadingMessage extends StatefulWidget {
  const RotatingRecipeLoadingMessage({
    super.key,
    required this.isStreaming,
  });

  final bool isStreaming;

  @override
  State<RotatingRecipeLoadingMessage> createState() =>
      _RotatingRecipeLoadingMessageState();
}

class _RotatingRecipeLoadingMessageState
    extends State<RotatingRecipeLoadingMessage> {
  static const Duration _rotationInterval = Duration(seconds: 3);

  Timer? _timer;
  int _index = 0;

  List<String> _activeMessages(AppLocalizations l10n) {
    final base = l10n.recipeGenerationLoadingPhrases;
    if (base.isEmpty) {
      return [l10n.sendingTastyRecipes];
    }
    final merged = [
      ...base,
      if (widget.isStreaming)
        ...l10n.recipeGenerationLoadingPhrasesStreamingExtras,
    ];
    return merged.isEmpty ? [l10n.sendingTastyRecipes] : merged;
  }

  void _syncTimer() {
    final messages = _activeMessages(context.l10n);
    if (messages.length <= 1) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    _timer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted) return;
      setState(() {
        final len = _activeMessages(context.l10n).length;
        _index = len <= 1 ? 0 : (_index + 1) % len;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(RotatingRecipeLoadingMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isStreaming != widget.isStreaming) {
      final len = _activeMessages(context.l10n).length;
      if (len <= 1) {
        _index = 0;
      } else if (_index >= len) {
        _index = 0;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _activeMessages(context.l10n);
    final text = messages[_index % messages.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeOut,
        child: Text(
          text,
          key: ValueKey<int>(_index),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                  ) ??
              const TextStyle(fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
