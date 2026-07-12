import '../l10n/app_localizations.dart';
import '../onboarding/onboarding_prefs.dart';

/// One row in the Standard vs Premium comparison table.
class TierFeatureRow {
  const TierFeatureRow({
    required this.label,
    required this.standardValue,
    this.premiumValue,
    this.premiumIsCheck = false,
  });

  final String label;
  final String standardValue;
  final String? premiumValue;
  final bool premiumIsCheck;
}

/// Tier limits aligned with backend rate_limits.js and meal_plan.js.
abstract final class TierFeatures {
  static const freeMealPlanDays = 3;
  static const premiumMealPlanDays = 7;

  static List<TierFeatureRow> rows(AppLocalizations l10n) => [
        TierFeatureRow(
          label: l10n.tierFeatureRecipeGenerations,
          standardValue: l10n.tierValuePerDay(
            OnboardingPrefs.freeTierDailyRecipeLimit,
          ),
          premiumValue: l10n.tierValueUnlimited,
        ),
        TierFeatureRow(
          label: l10n.tierFeatureImports,
          standardValue: l10n.tierValuePerDay(
            OnboardingPrefs.freeTierDailyImportLimit,
          ),
          premiumValue: l10n.tierValueUnlimited,
        ),
        TierFeatureRow(
          label: l10n.tierFeaturePantryScan,
          standardValue: l10n.tierValueNotIncluded,
          premiumIsCheck: true,
        ),
        TierFeatureRow(
          label: l10n.tierFeatureMealPlanner,
          standardValue: l10n.tierValueDays(freeMealPlanDays),
          premiumValue: l10n.tierValueDays(premiumMealPlanDays),
        ),
      ];
}
