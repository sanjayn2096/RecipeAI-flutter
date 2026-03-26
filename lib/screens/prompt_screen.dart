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
  /// Shown as AppBar back when non-null (previous questionnaire step or close pushed flow).
  final VoidCallback? onBack;

  String get _title => AppStrings.titleForRoute(route);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Room for up to ~4 lines of [titleLarge] when questions are long.
        toolbarHeight: 112,
        title: Text(
          _title,
          maxLines: 4,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        automaticallyImplyLeading: false,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: AppStrings.back,
                onPressed: onBack,
              )
            : null,
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
