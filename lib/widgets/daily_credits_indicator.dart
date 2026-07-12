import 'package:flutter/material.dart';

import '../core/l10n_context.dart';
import '../core/monetization_navigation.dart';
import '../core/telemetry/app_telemetry.dart';
import '../services/session_manager.dart';
import '../view_models/subscription_view_model.dart';

/// Compact pill showing daily recipe credits for signed-in free users.
class DailyCreditsIndicator extends StatelessWidget {
  const DailyCreditsIndicator({
    super.key,
    required this.sessionManager,
    required this.subscriptionViewModel,
    required this.appTelemetry,
  });

  final SessionManager sessionManager;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        subscriptionViewModel,
        sessionManager.usageQuotaRevision,
      ]),
      builder: (context, _) {
        if (subscriptionViewModel.isPremium || sessionManager.isGuestMode()) {
          return const SizedBox.shrink();
        }

        final usage =
            sessionManager.getSignedInRecipeGenerationUsageForTodaySync();
        final used = usage.count;
        final total = usage.dailyLimit;
        final atLimit = used >= total;
        final scheme = Theme.of(context).colorScheme;

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openPremiumPaywall(
                context,
                source: 'credits_indicator',
                appTelemetry: appTelemetry,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  context.l10n.dailyCreditsUsed(used, total),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            atLimit ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
