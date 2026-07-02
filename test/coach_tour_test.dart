import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/tutorial/coach_tour.dart';

import 'l10n_test_helper.dart';

void main() {
  final l10n = englishL10n();

  test('main coach tour includes import spotlight steps', () {
    final navKey = GlobalKey();
    final getRecipesKey = GlobalKey();
    final pantryKey = GlobalKey();
    final importLinksKey = GlobalKey();
    final importPasteKey = GlobalKey();
    final importScanKey = GlobalKey();
    final favoritesKey = GlobalKey();

    final steps = <CoachTourStep>[
      CoachTourStep(
        targetKey: navKey,
        title: l10n.coachStepNavTitle,
        body: l10n.coachStepNavBody,
        tabIndex: 0,
      ),
      CoachTourStep(
        targetKey: getRecipesKey,
        title: l10n.coachStepGetRecipesTitle,
        body: l10n.coachStepGetRecipesBody,
        tabIndex: 0,
      ),
      CoachTourStep(
        targetKey: pantryKey,
        title: l10n.coachStepAddPantryTitle,
        body: l10n.coachStepAddPantryBody,
        tabIndex: 0,
      ),
      CoachTourStep(
        targetKey: importLinksKey,
        title: l10n.coachStepImportLinksTitle,
        body: l10n.coachStepImportLinksBody,
        tabIndex: 3,
      ),
      CoachTourStep(
        targetKey: importPasteKey,
        title: l10n.coachStepImportPasteTitle,
        body: l10n.coachStepImportPasteBody,
        tabIndex: 3,
      ),
      CoachTourStep(
        targetKey: importScanKey,
        title: l10n.coachStepImportScanTitle,
        body: l10n.coachStepImportScanBody,
        tabIndex: 3,
      ),
      CoachTourStep(
        targetKey: favoritesKey,
        title: l10n.coachStepFavoritesTitle,
        body: l10n.coachStepFavoritesBody,
        tabIndex: 4,
      ),
    ];

    expect(steps, hasLength(7));
    expect(
      steps.where((s) => s.tabIndex == 3).map((s) => s.title).toList(),
      [
        l10n.coachStepImportLinksTitle,
        l10n.coachStepImportPasteTitle,
        l10n.coachStepImportScanTitle,
      ],
    );
    expect(steps.last.tabIndex, 4);
  });

  test('CoachTourController advances through import steps', () {
    final controller = CoachTourController(
      steps: [
        CoachTourStep(
          targetKey: GlobalKey(),
          title: 'Pantry',
          body: 'body',
          tabIndex: 0,
        ),
        CoachTourStep(
          targetKey: GlobalKey(),
          title: l10n.coachStepImportLinksTitle,
          body: l10n.coachStepImportLinksBody,
          tabIndex: 3,
        ),
        CoachTourStep(
          targetKey: GlobalKey(),
          title: l10n.coachStepFavoritesTitle,
          body: l10n.coachStepFavoritesBody,
          tabIndex: 4,
        ),
      ],
    );

    controller.start();
    expect(controller.currentIndex, 0);
    expect(controller.isLastStep, isFalse);

    controller.next();
    expect(controller.currentStep?.title, l10n.coachStepImportLinksTitle);
    expect(controller.currentStep?.tabIndex, 3);

    controller.next();
    expect(controller.currentStep?.title, l10n.coachStepFavoritesTitle);
    expect(controller.isLastStep, isTrue);

    controller.next();
    expect(controller.isActive, isFalse);
  });
}
