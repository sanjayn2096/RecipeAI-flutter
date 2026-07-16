import 'package:flutter/material.dart';

import '../core/l10n_context.dart';
import '../services/session_manager.dart';
import '../view_models/subscription_view_model.dart';
import 'brand_outlined_surface.dart';

/// Profile avatar with a daily-credits progress ring and compact `used/total`
/// label for signed-in free users. Premium and guest see the plain avatar.
class DailyCreditsIndicator extends StatelessWidget {
  const DailyCreditsIndicator({
    super.key,
    required this.avatarLabel,
    required this.sessionManager,
    required this.subscriptionViewModel,
    this.avatarRadius = 20,
  });

  final String avatarLabel;
  final SessionManager sessionManager;
  final SubscriptionViewModel subscriptionViewModel;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    final avatar = BrandOutlinedAvatar(
      label: avatarLabel,
      radius: avatarRadius,
    );

    return ListenableBuilder(
      listenable: Listenable.merge([
        subscriptionViewModel,
        sessionManager.usageQuotaRevision,
      ]),
      builder: (context, _) {
        if (subscriptionViewModel.isPremium || sessionManager.isGuestMode()) {
          return avatar;
        }

        final usage =
            sessionManager.getSignedInRecipeGenerationUsageForTodaySync();
        final used = usage.count;
        final total = usage.dailyLimit;
        final atLimit = total > 0 && used >= total;
        final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
        final scheme = Theme.of(context).colorScheme;
        const stroke = 2.5;
        final ringSize = avatarRadius * 2 + stroke * 2 + 2;

        return Tooltip(
          message: context.l10n.dailyCreditsUsedTooltip(used, total),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: ringSize,
                height: ringSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: ringSize,
                      height: ringSize,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: stroke,
                        backgroundColor:
                            scheme.onSurfaceVariant.withValues(alpha: 0.22),
                        color: scheme.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    avatar,
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.dailyCreditsUsed(used, total),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: atLimit ? scheme.primary : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
