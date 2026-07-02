import 'package:flutter/material.dart';

import '../core/l10n_context.dart';
import '../core/l10n_extensions.dart';

class PromptScreen extends StatelessWidget {
  const PromptScreen({
    super.key,
    required this.route,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onNext,
    this.onBack,
    this.appBarActions,
  });

  final String route;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onNext;
  /// Shown as AppBar back when non-null (previous questionnaire step or close pushed flow).
  final VoidCallback? onBack;
  /// Extra actions (e.g. shell app menu when embedded in [HomeShellScreen]).
  final List<Widget>? appBarActions;

  String _labelForOption(BuildContext context, String key) {
    final l10n = context.l10n;
    switch (route) {
      case 'mood':
        return l10n.moodLabel(key);
      case 'dietRestrictions':
        return l10n.dietLabel(key);
      case 'cuisinePreferences':
        return l10n.cuisineLabel(key);
      case 'cookingPreferences':
        return l10n.cookingLabel(key);
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        // Room for up to ~4 lines of [titleLarge] when questions are long.
        toolbarHeight: 112,
        title: Text(
          l10n.titleForRoute(route),
          maxLines: 4,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        automaticallyImplyLeading: false,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.back,
                onPressed: onBack,
              )
            : null,
        actions: appBarActions ?? const [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: options
                    .map(
                      (key) => RadioListTile<String>(
                        title: Text(_labelForOption(context, key)),
                        value: key,
                        groupValue: selectedOption,
                        onChanged: (v) {
                          if (v != null) onOptionSelected(v);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: selectedOption != null ? onNext : null,
              child: Text(l10n.next),
            ),
          ],
        ),
      ),
    );
  }
}
