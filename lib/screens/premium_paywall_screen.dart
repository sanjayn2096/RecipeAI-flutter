import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/monetization_config.dart';
import '../core/subscription_log.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../services/session_manager.dart';
import '../view_models/login_view_model.dart';
import '../view_models/subscription_view_model.dart';
import '../widgets/tier_comparison_table.dart';

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
    subscriptionLog('paywall subscribe tap source=${widget.source}');
    if (widget.sessionManager.isGuestMode()) {
      subscriptionLog('paywall subscribe: redirect guest → login');
      await widget.appTelemetry.logPremiumSubscribeLoginRedirect(
        source: widget.source,
      );
      if (!mounted) return;
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
    await widget.subscriptionViewModel.subscribe(source: widget.source);
  }

  Future<void> _onRestore() async {
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.premiumRestore,
      action: 'tap',
    );
    await widget.appTelemetry.logPremiumRestoreTap();
    await widget.subscriptionViewModel.restorePurchases();
  }

  Future<void> _onPromoCodeTap() async {
    if (widget.sessionManager.isGuestMode()) {
      context.go('/login', extra: true);
      return;
    }
    await widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.premiumPromoRedeem,
      action: 'tap',
    );
    if (!mounted) return;
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => const _PromoCodeDialog(),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    final ok = await widget.subscriptionViewModel.redeemPromoCode(code);
    if (!mounted) return;
    if (ok) {
      final expiresMs = widget.subscriptionViewModel.status.expiresAtMs;
      String message = 'Premium unlocked with your promo code.';
      if (expiresMs != null) {
        final expires = DateTime.fromMillisecondsSinceEpoch(expiresMs);
        final formatted =
            '${expires.year}-${expires.month.toString().padLeft(2, '0')}-${expires.day.toString().padLeft(2, '0')}';
        message = 'Premium unlocked until $formatted.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
                      'Sous Chef Premium',
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
                    const SizedBox(height: 20),
                    const TierComparisonTable(),
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
                    const SizedBox(height: 8),
                    Text(
                      MonetizationConfig.developerName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
                      TextButton(
                        onPressed: vm.loading ? null : _onPromoCodeTap,
                        child: const Text('Have a promo code?'),
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

class _PromoCodeDialog extends StatefulWidget {
  const _PromoCodeDialog();

  @override
  State<_PromoCodeDialog> createState() => _PromoCodeDialogState();
}

class _PromoCodeDialogState extends State<_PromoCodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter promo code'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'SOUSCHEF-XXXXXX',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          final trimmed = value.trim();
          if (trimmed.isNotEmpty) Navigator.of(context).pop(trimmed);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isEmpty) return;
            Navigator.of(context).pop(trimmed);
          },
          child: const Text('Redeem'),
        ),
      ],
    );
  }
}
