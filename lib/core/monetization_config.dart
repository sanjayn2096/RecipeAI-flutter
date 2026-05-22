/// Ad units, subscription SKU, and legal URLs (override via --dart-define).
class MonetizationConfig {
  MonetizationConfig._();

  static const String standardProductId = String.fromEnvironment(
    'PREMIUM_PRODUCT_ID',
    defaultValue: 'sous_chef_standard_monthly',
  );

  static const String monthlyPriceDisplay = String.fromEnvironment(
    'PREMIUM_PRICE_DISPLAY',
    defaultValue: '\$5.99',
  );

  /// Google test banner (replace in release with your ad unit).
  static const String androidBannerAdUnitId = String.fromEnvironment(
    'ANDROID_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );

  static const String iosBannerAdUnitId = String.fromEnvironment(
    'IOS_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  );

  static const String termsUrl = String.fromEnvironment(
    'TERMS_URL',
    defaultValue: 'https://souschefai.app/terms',
  );

  static const String privacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
    defaultValue: 'https://souschefai.app/privacy',
  );
}
