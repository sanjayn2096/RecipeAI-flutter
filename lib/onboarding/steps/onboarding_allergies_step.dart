import 'package:flutter/material.dart';

import '../../core/l10n_context.dart';
import '../../core/l10n_extensions.dart';
import '../../core/preference_options.dart';
import '../onboarding_controller.dart';
import '../widgets/animated_preference_chip.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

class OnboardingAllergiesStep extends StatefulWidget {
  const OnboardingAllergiesStep({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onContinue,
  });

  final OnboardingController controller;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<OnboardingAllergiesStep> createState() =>
      _OnboardingAllergiesStepState();
}

class _OnboardingAllergiesStepState extends State<OnboardingAllergiesStep> {
  bool _notesExpanded = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController =
        TextEditingController(text: widget.controller.allergyNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keys = PreferenceOptions.allergenKeys;
    final noneSelected = widget.controller.allergensAvoid.isEmpty;
    return OnboardingScaffold(
      currentStep: widget.controller.stepIndex,
      totalSteps: OnboardingController.stepCount,
      stepLabel: l10n.onboardingStepLabel(
        widget.controller.stepIndex + 1,
        OnboardingController.stepCount,
      ),
      title: l10n.onboardingAllergiesTitle,
      subtitle: l10n.onboardingAllergiesSubtitle,
      onBack: widget.onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaggeredEntrance(
            index: 0,
            child: AnimatedPreferenceChip(
              label: l10n.onboardingAllergiesNone,
              selected: noneSelected,
              onTap: widget.controller.clearAllergens,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < keys.length; i++)
                StaggeredEntrance(
                  index: i + 1,
                  child: AnimatedPreferenceChip(
                    label: l10n.allergenLabel(keys[i]),
                    selected: widget.controller.allergensAvoid.contains(keys[i]),
                    onTap: () => widget.controller.toggleAllergen(keys[i]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => setState(() => _notesExpanded = !_notesExpanded),
            icon: Icon(_notesExpanded ? Icons.expand_less : Icons.expand_more),
            label: Text(l10n.onboardingAllergiesAddNotes),
          ),
          if (_notesExpanded)
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: l10n.homeSearchSettingsAllergenNotesLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.controller.setAllergyNotes,
            ),
        ],
      ),
      bottom: FilledButton(
        onPressed: widget.controller.canContinue ? widget.onContinue : null,
        child: Text(l10n.next),
      ),
    );
  }
}
