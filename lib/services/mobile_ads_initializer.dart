import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/monetization_config.dart';

/// Lazy Mobile Ads SDK init so [main] does not block on the ads SDK at cold start.
abstract final class MobileAdsInitializer {
  MobileAdsInitializer._();

  static Future<void>? _initFuture;

  /// Idempotent; safe to call from splash (warm-up) or before the first banner load.
  static Future<void> ensureInitialized() {
    if (kIsWeb || !MonetizationConfig.adsEnabled) return Future.value();
    _initFuture ??= MobileAds.instance.initialize();
    return _initFuture!;
  }
}
