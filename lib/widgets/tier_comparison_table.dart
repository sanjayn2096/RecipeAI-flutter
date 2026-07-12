import 'package:flutter/material.dart';

import '../core/l10n_context.dart';
import '../core/tier_features.dart';

/// Standard vs Premium feature comparison for paywall screens.
class TierComparisonTable extends StatelessWidget {
  const TierComparisonTable({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rows = TierFeatures.rows(l10n);
    final hPad = compact ? 10.0 : 14.0;
    final vPad = compact ? 8.0 : 10.0;
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: compact ? 11 : 12,
        );
    final featureStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: compact ? 12 : 13,
        );
    final standardStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: compact ? 11 : 12,
        );
    final premiumStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : 12,
        );

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderRow(
            featureLabel: l10n.tierColumnFeature,
            standardLabel: l10n.tierColumnStandard,
            premiumLabel: l10n.tierColumnPremium,
            style: labelStyle,
            hPad: hPad,
            vPad: vPad,
            scheme: scheme,
          ),
          for (var i = 0; i < rows.length; i++)
            _DataRow(
              row: rows[i],
              featureStyle: featureStyle,
              standardStyle: standardStyle,
              premiumStyle: premiumStyle,
              hPad: hPad,
              vPad: vPad,
              scheme: scheme,
              showDivider: i < rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.featureLabel,
    required this.standardLabel,
    required this.premiumLabel,
    required this.style,
    required this.hPad,
    required this.vPad,
    required this.scheme,
  });

  final String featureLabel;
  final String standardLabel;
  final String premiumLabel;
  final TextStyle? style;
  final double hPad;
  final double vPad;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(featureLabel, style: style)),
          Expanded(
            flex: 3,
            child: Text(
              standardLabel,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                premiumLabel,
                style: style?.copyWith(color: scheme.onPrimaryContainer),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.row,
    required this.featureStyle,
    required this.standardStyle,
    required this.premiumStyle,
    required this.hPad,
    required this.vPad,
    required this.scheme,
    required this.showDivider,
  });

  final TierFeatureRow row;
  final TextStyle? featureStyle;
  final TextStyle? standardStyle;
  final TextStyle? premiumStyle;
  final double hPad;
  final double vPad;
  final ColorScheme scheme;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: Text(row.label, style: featureStyle)),
              Expanded(
                flex: 3,
                child: Text(
                  row.standardValue,
                  style: standardStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: row.premiumIsCheck
                      ? Center(
                          child: Icon(
                            Icons.check,
                            size: 18,
                            color: scheme.primary,
                          ),
                        )
                      : Text(
                          row.premiumValue ?? '',
                          style: premiumStyle,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}
