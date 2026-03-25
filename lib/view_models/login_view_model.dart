import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository authRepository})
      : _auth = authRepository;

  final AuthRepository _auth;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> checkSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _isLoggedIn = await _auth.checkSession();
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
      _isLoggedIn = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
      _isLoggedIn = true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
