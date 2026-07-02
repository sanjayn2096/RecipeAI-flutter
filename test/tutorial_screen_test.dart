import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_ai/l10n/app_localizations.dart';
import 'package:recipe_ai/screens/tutorial_screen.dart';

import 'l10n_test_helper.dart';

void main() {
  final l10n = englishL10n();

  Future<void> pumpTutorial(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/tutorial',
      routes: [
        GoRoute(
          path: '/tutorial',
          builder: (_, __) => const TutorialScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tutorial walkthrough includes import recipes page', (tester) async {
    await pumpTutorial(tester);

    expect(find.text(l10n.tutorialOverviewTitle), findsOneWidget);
    expect(find.text(l10n.tutorialImportTitle), findsNothing);

    await tester.tap(find.text(l10n.next));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tutorialCreateRecipesTitle), findsOneWidget);

    await tester.tap(find.text(l10n.next));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tutorialPantryTitle), findsOneWidget);

    await tester.tap(find.text(l10n.next));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tutorialImportTitle), findsOneWidget);
    expect(find.text(l10n.tutorialImportBody), findsOneWidget);
    expect(find.textContaining(l10n.importHubTileLinks), findsOneWidget);
    expect(find.textContaining(l10n.importHubTileScan), findsOneWidget);

    await tester.tap(find.text(l10n.next));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tutorialFavoritesTitle), findsOneWidget);
  });

  testWidgets('tutorial page indicators reflect five steps', (tester) async {
    await pumpTutorial(tester);

    expect(
      find.descendant(
        of: find.byType(TutorialScreen),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(5),
    );
  });

  testWidgets('overview copy mentions Import tab', (tester) async {
    await pumpTutorial(tester);

    expect(find.textContaining('Import to bring in recipes'), findsOneWidget);
    expect(find.textContaining('five tabs'), findsOneWidget);
  });
}
