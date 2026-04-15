import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/session_manager.dart';
import 'api_call_context.dart';

/// Firebase Analytics for API timing, feature usage, and user identity.
class AppTelemetry {
  AppTelemetry(this._analytics);

  final FirebaseAnalytics _analytics;

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
