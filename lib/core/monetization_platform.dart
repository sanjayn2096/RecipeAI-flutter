import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// iOS App Store monetization is paused (tax / Paid Apps Agreement).
/// Paywall + IAP stay in the codebase for Android (and future iOS re-enable).
bool get isIosPaidMonetizationDisabled =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
