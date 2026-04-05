import 'package:flutter/foundation.dart';

import '../core/auth_error_message.dart';
import '../data/repositories/auth_repository.dart';
import '../services/session_manager.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    required AuthRepository authRepository,
    required SessionManager sessionManager,
  })  : _auth = authRepository,
        _session = sessionManager;

  final AuthRepository _auth;
  final SessionManager _session;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isGuestMode => _session.isGuestMode();

  /// Browse without signing in. Cleared when the user logs in or signs up.
  Future<void> enterGuestMode() async {
    _errorMessage = null;
    _session.setGuestModeSync(true);
    await _session.getOrCreateAnonymousId();
    notifyListeners();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _isLoggedIn = await _auth.checkSession();
      if (_isLoggedIn) {
        _session.clearGuestModeSync();
        _session.clearAnonymousAndGuestQuotaSync();
      }
    } catch (_) {
      _isLoggedIn = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.login(email, password);
      _session.clearGuestModeSync();
      _session.clearAnonymousAndGuestQuotaSync();
      _isLoggedIn = true;
    } catch (e) {
      _errorMessage = authErrorMessage(e);
    }
    notifyListeners();
  }

  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      _session.clearGuestModeSync();
      _session.clearAnonymousAndGuestQuotaSync();
      _isLoggedIn = true;
    } catch (e) {
      _errorMessage = authErrorMessage(e);
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Call when user signs out so the login screen shows the form instead of redirecting to home.
  void setLoggedOut() {
    _isLoggedIn = false;
    notifyListeners();
  }
}
