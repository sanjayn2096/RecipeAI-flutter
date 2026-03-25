import 'package:flutter/material.dart';

import '../core/app_strings.dart';

class PromptScreen extends StatelessWidget {
  const PromptScreen({
    super.key,
    required this.route,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.onNext,
    this.onBack,
  });

  final String route;
  final List<String> options;
  final String? selectedOption;
  final ValueChanged<String> onOptionSelected;
  final VoidCallback onNext;
  /// When set, shows an AppBar back control to return to the previous questionnaire step.
  final VoidCallback? onBack;

  String get _title => AppStrings.titleForRoute(route);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
        automaticallyImplyLeading: false,
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
                      (opt) => RadioListTile<String>(
                        title: Text(opt),
                        value: opt,
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
              child: const Text(AppStrings.next),
            ),
          ],
        ),
      ),
    );
  }
}
