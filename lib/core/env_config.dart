/// Environment-based config. Add dev/staging later via --dart-define=ENV=dev.
class EnvConfig {
  EnvConfig._();

  static const String env =
      String.fromEnvironment('ENV', defaultValue: 'prod');

  static const Map<String, String> _baseUrls = {
    'prod': 'https://api-sdly2fmmrq-uc.a.run.app',
    // Add when you have them:
    // 'staging': 'https://your-staging-url.run.app',
    // 'dev': 'https://your-dev-url.run.app',
  };

  static String get baseUrl =>
      _baseUrls[env] ?? _baseUrls['prod']!;
}
