import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../services/session_manager.dart';
import 'api_call_context.dart';
import 'device_identity.dart';
import 'firestore_activity_metrics.dart';

/// Firebase Analytics for API timing, feature usage, and user identity.
class AppTelemetry {
  AppTelemetry(this._analytics);

  final FirebaseAnalytics _analytics;
  DeviceIdentity? _device;

  static const _maxParamLen = 100;

  Future<void> logApiCall(ApiCallMetrics m) async {
    await _analytics.logEvent(
      name: 'api_call',
      parameters: {
        'path': _truncate(m.path, _maxParamLen),
        'method': m.method,
        'status_code': m.statusCode,
        'duration_ms': m.durationMs,
        'actor_type': m.actorType.name,
        'actor_id': _truncate(m.actorId, _maxParamLen),
        if (m.errorMessage != null)
          'error': _truncate(m.errorMessage!, _maxParamLen),
      },
    );
  }

  /// Registers install id + platform on Analytics for per-device Firestore attribution.
  Future<void> initDeviceIdentity(SessionManager session) async {
    final device = await DeviceIdentity.load(session);
    _device = device;
    await _analytics.setUserProperty(
      name: 'install_id',
      value: _truncate(device.installId, _maxParamLen),
    );
    await _analytics.setUserProperty(name: 'platform', value: device.platform);
  }

  /// Client-side Firestore activity (listeners + direct writes).
  Future<void> logFirestoreActivity(FirestoreActivityMetrics m) async {
    final device = _device;
    if (kDebugMode) {
      debugPrint(
        '[Firestore] ${m.operation} ${m.collection} docs=${m.docCount} '
        'device=${device?.label ?? 'unknown'}',
      );
    }
    await _analytics.logEvent(
      name: 'firestore_activity',
      parameters: {
        'operation': _truncate(m.operation, _maxParamLen),
        'collection': _truncate(m.collection, _maxParamLen),
        'doc_count': m.docCount,
        if (device != null) 'install_id': _truncate(device.installId, 32),
        if (device != null) 'platform': device.platform,
      },
    );
  }

  Future<void> logFeatureInteraction({
    required String featureId,
    String action = 'tap',
  }) async {
    await _analytics.logEvent(
      name: 'feature_interaction',
      parameters: {
        'feature_id': _truncate(featureId, _maxParamLen),
        'action': _truncate(action, _maxParamLen),
      },
    );
  }

  Future<void> setSubscriptionTier(String tier) async {
    await _analytics.setUserProperty(name: 'subscription_tier', value: tier);
  }

  Future<void> logPremiumCtaTap({required String source}) async {
    await _analytics.logEvent(
      name: 'premium_cta_tap',
      parameters: {'source': _truncate(source, _maxParamLen)},
    );
  }

  Future<void> logPremiumPaywallView({required String source}) async {
    await _analytics.logEvent(
      name: 'premium_paywall_view',
      parameters: {'source': _truncate(source, _maxParamLen)},
    );
  }

  Future<void> logPremiumPaywallScroll({required String maxSection}) async {
    await _analytics.logEvent(
      name: 'premium_paywall_scroll',
      parameters: {'max_section': _truncate(maxSection, _maxParamLen)},
    );
  }

  Future<void> logPremiumSubscribeTap({
    required String source,
    required String productId,
  }) async {
    await _analytics.logEvent(
      name: 'premium_subscribe_tap',
      parameters: {
        'source': _truncate(source, _maxParamLen),
        'product_id': _truncate(productId, _maxParamLen),
      },
    );
  }

  Future<void> logPremiumPurchaseResult({
    required String result,
    String? errorCode,
  }) async {
    await _analytics.logEvent(
      name: 'premium_purchase_result',
      parameters: {
        'result': _truncate(result, _maxParamLen),
        if (errorCode != null)
          'error_code': _truncate(errorCode, _maxParamLen),
      },
    );
  }

  Future<void> logPremiumRestoreTap() async {
    await _analytics.logEvent(name: 'premium_restore_tap');
  }

  Future<void> logPremiumPaywallDismiss({
    required String source,
    required int secondsOnScreen,
  }) async {
    await _analytics.logEvent(
      name: 'premium_paywall_dismiss',
      parameters: {
        'source': _truncate(source, _maxParamLen),
        'seconds_on_screen': secondsOnScreen,
      },
    );
  }

  /// Aligns Analytics user id and [user_type] with Firebase Auth + guest mode.
  Future<void> syncUserIdentity(SessionManager session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _analytics.setUserId(id: user.uid);
      await _analytics.setUserProperty(name: 'user_type', value: 'signed_in');
    } else {
      await _analytics.setUserId(id: null);
      final type = session.isGuestMode() ? 'guest' : 'signed_out';
      await _analytics.setUserProperty(name: 'user_type', value: type);
    }
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);
}
