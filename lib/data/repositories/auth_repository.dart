import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_service.dart';
import '../models/api_dtos.dart';
import '../../services/session_manager.dart';

/// Auth operations: Firebase sign-in, backend login/signup/session check.
/// Fix: Single repository for auth instead of calling API from ViewModel.
class AuthRepository {
  AuthRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
    FirebaseAuth? firebaseAuth,
  })  : _api = apiService,
        _session = sessionManager,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final ApiService _api;
  final SessionManager _session;
  final FirebaseAuth _firebaseAuth;

  /// Returns true if existing session is valid.
  Future<bool> checkSession() async {
    final sessionId = _session.getSession();
    if (sessionId == null) return false;
    try {
      final res = await _api.checkSession(SessionCheckRequest(sessionId: sessionId));
      if (res.message != null) return true;
    } catch (_) {
      await _session.clearSession();
    }
    return false;
  }

  /// Sign in with Firebase, then register session with backend.
  Future<void> login(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) throw Exception('Login failed');
    final sessionId = _generateSessionId();
    await _session.saveSession(sessionId);
    final res = await _api.login(LoginRequest(email: email, tokenId: sessionId));
    if (res.userId != null) {
      await _session.saveEmail(email);
      await _session.saveUserId(res.userId!);
    }
  }

  /// Sign up via backend (backend creates Firebase user). After success, sign in
  /// with Firebase so the user is logged in on this device.
  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final res = await _api.signup(SignupRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    ));
    if (res.userId == null) throw Exception(res.message ?? 'Signup failed');
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final sessionId = _generateSessionId();
    await _session.saveSession(sessionId);
    await _session.saveEmail(email);
    await _session.saveUserId(res.userId!);
  }

  /// Sign out: backend signout + clear session + Firebase signOut (arch fix).
  Future<void> signOut() async {
    final email = _session.getEmail();
    if (email != null && email.isNotEmpty) {
      try {
        await _api.signout(SignoutRequest(email: email));
      } catch (_) {}
    }
    await _firebaseAuth.signOut();
    await _session.clearSession();
  }

  static String _generateSessionId() {
    // Simple UUID-like id for session
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }
}
