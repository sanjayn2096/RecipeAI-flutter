import 'package:flutter/foundation.dart';

import '../../services/session_manager.dart';

/// Stable per-install identity for attributing Firestore usage to a device.
class DeviceIdentity {
  DeviceIdentity({
    required this.installId,
    required this.platform,
  });

  final String installId;
  final String platform;

  String get label => '$platform:${installId.substring(0, 8)}';

  static Future<DeviceIdentity> load(SessionManager session) async {
    final installId = await session.getOrCreateInstallId();
    return DeviceIdentity(
      installId: installId,
      platform: _platformLabel(),
    );
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
