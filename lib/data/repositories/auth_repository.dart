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
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  /// GET get_user_profile: at most once per signed-in Firebase user while the app is running
  /// (no duplicate calls from Profile or other screens; a new app launch will call again on [checkSession]/login).
  String? _profileFetchedForFirebaseUid;

  Future<void> _fetchAndPersistUserProfileOnce(User firebaseUser) async {
    if (_profileFetchedForFirebaseUid == firebaseUser.uid) {
      return;
    }
    final token = await firebaseUser.getIdToken();
    final profile = await _api.getUserProfile(idToken: token);
    await _persistProfileFromResponse(firebaseUser, profile);
    _profileFetchedForFirebaseUid = firebaseUser.uid;
  }

  Future<void> _persistProfileFromResponse(User firebaseUser, UserProfileResponse profile) async {
    final emailFromFirebase = firebaseUser.email ?? '';
    final email = (profile.email != null && profile.email!.trim().isNotEmpty)
        ? profile.email!.trim()
        : emailFromFirebase;
    await _session.persistUserProfile(
      userId: profile.userId,
      email: email,
      firstName: profile.firstName,
      lastName: profile.lastName,
    );
  }

  /// Returns true if user is already signed in (Firebase + backend profile).
  /// Uses Firebase Auth persistence; no backend check-session.
  Future<bool> checkSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    try {
      await _fetchAndPersistUserProfileOnce(user);
      return true;
    } catch (_) {
      await _firebaseAuth.signOut();
      await _session.clearSession();
      return false;
    }
  }

  /// Sign in with Firebase, then fetch user profile from backend (GET get_user_profile).
  /// No /login API; backend identifies user via Firebase ID token if sent.
  Future<void> login(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) throw Exception('Login failed');
    await _fetchAndPersistUserProfileOnce(cred.user!);
  }

  /// Sign up via backend (backend creates Firebase user). After success, sign in
  /// with Firebase and fetch profile (same as login).
  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final signupResult = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (signupResult.user == null) {
      throw Exception('Signup failed, retry again');
    } else {
      try {
      final sessionId = _generateSessionId();
      await _session.saveSession(sessionId);
      final displayName = '$firstName $lastName'.trim();
      if (displayName.isNotEmpty) {
        await signupResult.user!.updateDisplayName(displayName);
      }
      final resolvedEmail = signupResult.user!.email ?? email;
      await _persistProfileFromResponse(
          signupResult.user!,
          UserProfileResponse(
            userId: signupResult.user!.uid,
            email: resolvedEmail,
            firstName: firstName,
            lastName: lastName,
          ));
      } catch (e) {
        _errorMessage = e.toString().replaceFirst('Signup Update Exception: ', '');
      }
    }
  }

  /// Sign out: Firebase Auth signOut on device + clear local session. No backend call.
  Future<void> signOut() async {
    _profileFetchedForFirebaseUid = null;
    await _firebaseAuth.signOut();
    await _session.clearSession();
  }

  static String _generateSessionId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
  }
}
