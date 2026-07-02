import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/monetization_config.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../services/session_manager.dart';
import '../view_models/login_view_model.dart';
import '../view_models/subscription_view_model.dart';

/// Premium subscription paywall with purchase funnel analytics.
class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({
    super.key,
    required this.source,
    required this.subscriptionViewModel,
    required this.sessionManager,
    required this.loginViewModel,
    required this.appTelemetry,
  });

  final String source;
  final SubscriptionViewModel subscriptionViewModel;
  final SessionManager sessionManager;
  final LoginViewModel loginViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime _openedAt = DateTime.now();
  String _maxSection = 'hero';

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
    widget.appTelemetry.logPremiumPaywallView(source: widget.source);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    String section = 'hero';
    if (offset > 320) {
      section = 'legal';
    } else if (offset > 160) {
      section = 'benefits';
    }
    if (section != _maxSection) {
      _maxSection = section;
      widget.appTelemetry.logPremiumPaywallScroll(maxSection: _maxSection);
    }
  }

  @override
  void dispose() {
    widget.subscriptionViewModel.resetPurchaseUiState();
    final seconds = DateTime.now().difference(_openedAt).inSeconds;
    widget.appTelemetry.logPremiumPaywallDismiss(
      source: widget.source,
      secondsOnScreen: seconds,
    );
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _onSubscribe() async {
    if (widget.sessionManager.isGuestMode()) {
      context.go('/login', extra: true);
      return;
    }
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.premiumSubscribe,
      action: 'tap',
    );
    await widget.appTelemetry.logPremiumSubscribeTap(
      source: widget.source,
      productId: MonetizationConfig.standardProductId,
    );
    await widget.subscriptionViewModel.subscribe();
  }

  Future<void> _onRestore() async {
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.premiumRestore,
      action: 'tap',
    );
    await widget.appTelemetry.logPremiumRestoreTap();
    await widget.subscriptionViewModel.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = widget.subscriptionViewModel.product?.price ??
        '${MonetizationConfig.monthlyPriceDisplay}/month';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sous Chef Premium'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.subscriptionViewModel,
        builder: (context, _) {
          final vm = widget.subscriptionViewModel;
          if (vm.isPremium) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 56, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'You’re a Premium member',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Text(
                      'Standard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Billed monthly. Auto-renews until canceled in App Store or Google Play settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _BenefitRow(
                      icon: Icons.all_inclusive,
                      title: 'Unlimited recipes',
                      subtitle:
                          'No daily cap on AI recipe generations.',
                    ),
                    _BenefitRow(
                      icon: Icons.camera_alt_outlined,
                      title: 'Pantry scan',
                      subtitle:
                          'Scan pantry or fridge photos to add staples instantly.',
                    ),
                    _BenefitRow(
                      icon: Icons.download_for_offline_outlined,
                      title: 'Unlimited imports',
                      subtitle:
                          'Import recipes from links, text, or photos without daily limits.',
                    ),
                    _BenefitRow(
                      icon: Icons.new_releases_outlined,
                      title: 'Latest recipes',
                      subtitle:
                          'Subscriber-only feed of the newest recipes in the community.',
                    ),
                    if (vm.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        vm.error!,
                        style: TextStyle(color: scheme.error),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Text(
                      'Payment will be charged to your App Store or Google Play account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Manage or cancel in your device subscription settings.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      children: [
                        TextButton(
                          onPressed: () =>
                              _openUrl(MonetizationConfig.termsUrl),
                          child: const Text('Terms of Service'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _openUrl(MonetizationConfig.privacyUrl),
                          child: const Text('Privacy Policy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: vm.loading ? null : _onSubscribe,
                        child: vm.loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.sessionManager.isGuestMode()
                                    ? 'Sign in to subscribe'
                                    : 'Subscribe',
                              ),
                      ),
                      TextButton(
                        onPressed: vm.loading ? null : _onRestore,
                        child: const Text('Restore purchases'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
