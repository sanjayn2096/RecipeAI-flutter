import 'package:flutter/foundation.dart';

import '../core/auth_error_message.dart';
import '../core/email_not_verified_exception.dart';
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

  bool _needsEmailVerification = false;
  bool get needsEmailVerification => _needsEmailVerification;

  String? _pendingVerificationEmail;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isGuestMode => _session.isGuestMode();

  void _clearVerificationPending() {
    _needsEmailVerification = false;
    _pendingVerificationEmail = null;
  }

  void _setVerificationPending(String? email) {
    _needsEmailVerification = true;
    _pendingVerificationEmail = email ?? _auth.currentUserEmail;
  }

  /// Browse without signing in. Cleared when the user logs in or signs up.
  Future<void> enterGuestMode() async {
    _errorMessage = null;
    _clearVerificationPending();
    await _auth.signOutFirebaseOnly();
    _session.setGuestModeSync(true);
    await _session.getOrCreateAnonymousId();
    notifyListeners();
  }

  Future<void> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _clearVerificationPending();
      _isLoggedIn = await _auth.checkSession();
      if (_isLoggedIn) {
        _session.clearGuestModeSync();
        _session.clearAnonymousAndGuestQuotaSync();
      } else if (_auth.hasUnverifiedFirebaseUser) {
        _setVerificationPending(_auth.currentUserEmail);
      }
    } catch (_) {
      _isLoggedIn = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _errorMessage = null;
    _clearVerificationPending();
    notifyListeners();
    try {
      await _auth.login(email, password);
      _session.clearGuestModeSync();
      _session.clearAnonymousAndGuestQuotaSync();
      _isLoggedIn = true;
    } on EmailNotVerifiedException {
      _setVerificationPending(email.trim());
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
    _clearVerificationPending();
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
    } on EmailNotVerifiedException {
      _setVerificationPending(email.trim());
    } catch (e) {
      _errorMessage = authErrorMessage(e);
    }
    notifyListeners();
  }

  Future<void> resendVerificationEmail() async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.sendEmailVerificationForCurrentUser();
    } catch (e) {
      _errorMessage = authErrorMessage(e);
    }
    notifyListeners();
  }

  /// When [showNotVerifiedMessage] is false, still-unverified is silent (for polling / resume).
  Future<void> refreshVerificationAndComplete({
    bool showNotVerifiedMessage = true,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final ok = await _auth.tryCompleteLoginIfVerified();
      if (ok) {
        _clearVerificationPending();
        _session.clearGuestModeSync();
        _session.clearAnonymousAndGuestQuotaSync();
        _isLoggedIn = true;
      } else if (showNotVerifiedMessage) {
        _errorMessage =
            'Not verified yet. Open the link in your email, then try again.';
      }
    } catch (e) {
      _errorMessage = authErrorMessage(e);
    }
    notifyListeners();
  }

  Future<void> cancelVerificationAndSignOut() async {
    _clearVerificationPending();
    await _auth.signOut();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Call when user signs out so the login screen shows the form instead of redirecting to home.
  void setLoggedOut() {
    _isLoggedIn = false;
    _clearVerificationPending();
    notifyListeners();
  }
}
