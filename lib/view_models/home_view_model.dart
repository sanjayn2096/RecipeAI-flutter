import 'package:flutter/foundation.dart';

import '../data/models/user_data.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  })  : _userRepo = userRepository,
        _authRepo = authRepository;

  final UserRepository _userRepo;
  final AuthRepository _authRepo;

  UserData? _userData;
  UserData? get userData => _userData;

  bool? _isSignedOut;
  bool? get isSignedOut => _isSignedOut;

  Future<void> loadUserDetails() async {
    _userData = await _userRepo.getUserDetails();
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
      _isSignedOut = true;
    } catch (_) {
      _isSignedOut = false;
    }
    notifyListeners();
  }

  void clearSignedOutFlag() {
    _isSignedOut = null;
    notifyListeners();
  }
}
