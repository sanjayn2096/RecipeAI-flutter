import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Fetches and caches config from Firebase Remote Config (e.g. Gemini API key).
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? instance})
      : _remoteConfig = instance ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  static const String _keyGeminiApiKey = 'gemini_api_key';

  String? _geminiApiKey;

  /// Ensures config is fetched at least once. Call early in app startup.
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _remoteConfig.fetchAndActivate();
    _geminiApiKey = _remoteConfig.getString(_keyGeminiApiKey);
    if (_geminiApiKey != null && _geminiApiKey!.isEmpty) {
      _geminiApiKey = null;
    }
  }

  /// Returns the Gemini API key from Remote Config, or null if not set.
  String? get geminiApiKey => _geminiApiKey;
}
