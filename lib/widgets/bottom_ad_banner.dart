import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/monetization_config.dart';
import '../core/monetization_navigation.dart';
import '../core/telemetry/app_telemetry.dart';
import '../services/mobile_ads_initializer.dart';
import '../view_models/subscription_view_model.dart';

/// Adaptive banner above the shell bottom navigation (mobile, non-premium).
class BottomAdBanner extends StatefulWidget {
  const BottomAdBanner({
    super.key,
    required this.subscriptionViewModel,
    required this.appTelemetry,
  });

  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<BottomAdBanner> createState() => _BottomAdBannerState();
}

class _BottomAdBannerState extends State<BottomAdBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  static const double _fallbackHeight = 50;

  bool _adRequested = false;

  @override
  void initState() {
    super.initState();
    widget.subscriptionViewModel.addListener(_onSubscriptionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adRequested) {
      _adRequested = true;
      _loadAd();
    }
  }

  @override
  void didUpdateWidget(covariant BottomAdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subscriptionViewModel != widget.subscriptionViewModel) {
      oldWidget.subscriptionViewModel.removeListener(_onSubscriptionChanged);
      widget.subscriptionViewModel.addListener(_onSubscriptionChanged);
      _loadAd();
    }
  }

  void _onSubscriptionChanged() {
    if (widget.subscriptionViewModel.isPremium) {
      _banner?.dispose();
      _banner = null;
      _loaded = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadAd() async {
    if (kIsWeb ||
        !MonetizationConfig.adsEnabled ||
        widget.subscriptionViewModel.isPremium) {
      return;
    }

    await MobileAdsInitializer.ensureInitialized();
    if (!mounted) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0) return;

    final adUnitId = defaultTargetPlatform == TargetPlatform.iOS
        ? MonetizationConfig.iosBannerAdUnitId
        : MonetizationConfig.androidBannerAdUnitId;

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _banner?.dispose();
    _banner = ad;
    await ad.load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.subscriptionViewModel.removeListener(_onSubscriptionChanged);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.subscriptionViewModel,
      builder: (context, _) {
        if (kIsWeb ||
            !MonetizationConfig.adsEnabled ||
            widget.subscriptionViewModel.isPremium) {
          return const SizedBox.shrink();
        }

        final height = _loaded && _banner != null
            ? _banner!.size.height.toDouble()
            : _fallbackHeight;

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => openPremiumPaywall(
                    context,
                    source: 'ad_banner',
                    appTelemetry: widget.appTelemetry,
                  ),
                  child: const Text('Remove ads'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: height,
                child: _loaded && _banner != null
                    ? AdWidget(ad: _banner!)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}
