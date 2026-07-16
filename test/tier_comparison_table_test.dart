import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/l10n/app_localizations.dart';
import 'package:recipe_ai/widgets/tier_comparison_table.dart';

import 'l10n_test_helper.dart';

void main() {
  final l10n = englishL10n();

  Future<void> pumpTable(WidgetTester tester, {bool compact = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: TierComparisonTable(compact: compact),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders four feature rows with column headers', (tester) async {
    await pumpTable(tester);

    expect(find.text(l10n.tierColumnFeature), findsOneWidget);
    expect(find.text(l10n.tierColumnStandard), findsOneWidget);
    expect(find.text(l10n.tierColumnPremium), findsOneWidget);

    expect(find.text(l10n.tierFeatureRecipeGenerations), findsOneWidget);
    expect(find.text(l10n.tierFeatureImports), findsOneWidget);
    expect(find.text(l10n.tierFeaturePantryScan), findsOneWidget);
    expect(find.text(l10n.tierFeatureMealPlanner), findsOneWidget);
    expect(find.text(l10n.tierFeatureLatestRecipes), findsNothing);
  });

  testWidgets('shows recipe limits and unlimited premium value', (tester) async {
    await pumpTable(tester);

    expect(find.text(l10n.tierValuePerDay(3)), findsOneWidget);
    expect(find.text(l10n.tierValuePerDay(1)), findsOneWidget);
    expect(find.text(l10n.tierValuePerWeek(2)), findsOneWidget);
    expect(find.text(l10n.tierValueUnlimited), findsNWidgets(3));
  });

  testWidgets('shows meal planner day limits without premium-only checks',
      (tester) async {
    await pumpTable(tester);

    expect(find.byIcon(Icons.check), findsNothing);
    expect(find.text(l10n.tierValueNotIncluded), findsNothing);
    expect(find.text(l10n.tierValueDays(3)), findsOneWidget);
    expect(find.text(l10n.tierValueDays(7)), findsOneWidget);
  });

  testWidgets('compact variant renders without overflow', (tester) async {
    await pumpTable(tester, compact: true);

    expect(find.byType(TierComparisonTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
