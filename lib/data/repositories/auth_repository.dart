import 'package:firebase_auth/firebase_auth.dart';

import '../../core/email_not_verified_exception.dart';
import '../api/api_service.dart';
import '../local/favorites_hive_store.dart';
import '../models/api_dtos.dart';
import '../../services/session_manager.dart';

/// Auth operations: Firebase sign-in/sign-up, then backend profile (GET get_user_profile).
class AuthRepository {
  AuthRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
    required FavoritesHiveStore favoritesHiveStore,
    FirebaseAuth? firebaseAuth,
  })  : _api = apiService,
        _session = sessionManager,
        _favoritesHiveStore = favoritesHiveStore,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final ApiService _api;
  final SessionManager _session;
  final FavoritesHiveStore _favoritesHiveStore;
  final FirebaseAuth _firebaseAuth;

  /// GET get_user_profile: at most once per signed-in Firebase user while the app is running
  /// (no duplicate calls from Profile or other screens; a new app launch will call again on [checkSession]/login).
  String? _profileFetchedForFirebaseUid;

  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// True when a Firebase session exists and the address is not verified.
  bool get hasUnverifiedFirebaseUser {
    final u = _firebaseAuth.currentUser;
    return u != null && !u.emailVerified;
  }

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

  /// Returns true if user is already signed in, email verified, and backend profile loaded.
  Future<bool> checkSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    await user.reload();
    final u = _firebaseAuth.currentUser;
    if (u == null) return false;
    if (!u.emailVerified) {
      return false;
    }
    try {
      await _fetchAndPersistUserProfileOnce(u);
      return true;
    } catch (_) {
      await _firebaseAuth.signOut();
      await _session.clearSession();
      return false;
    }
  }

  /// Sign in with Firebase, then fetch user profile from backend (GET get_user_profile).
  Future<void> login(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) throw Exception('Login failed');
    await cred.user!.reload();
    final u = _firebaseAuth.currentUser;
    if (u == null) throw Exception('Login failed');
    if (!u.emailVerified) {
      throw EmailNotVerifiedException();
    }
    await _fetchAndPersistUserProfileOnce(u);
  }

  /// Create the Firebase account on-device, send verification email, then require verified
  /// email before loading the backend profile ([getUserProfile]).
  Future<void> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) throw Exception('Sign up failed');

    final display = [firstName, lastName]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(' ');
    if (display.isNotEmpty) {
      await user.updateDisplayName(display);
    }

    await user.reload();
    final current = _firebaseAuth.currentUser;
    if (current == null) throw Exception('Sign up failed');
    if (!current.emailVerified) {
      await current.sendEmailVerification();
      throw EmailNotVerifiedException();
    }
    await _fetchAndPersistUserProfileOnce(current);
  }

  Future<void> sendEmailVerificationForCurrentUser() async {
    final u = _firebaseAuth.currentUser;
    if (u == null) return;
    await u.sendEmailVerification();
  }

  /// After the user taps the link in email: reload and hydrate session if verified.
  Future<bool> tryCompleteLoginIfVerified() async {
    final u = _firebaseAuth.currentUser;
    if (u == null) return false;
    await u.reload();
    final fresh = _firebaseAuth.currentUser;
    if (fresh == null || !fresh.emailVerified) {
      return false;
    }
    await _fetchAndPersistUserProfileOnce(fresh);
    return true;
  }

  /// Clears Firebase auth only — for entering guest mode from the login screen.
  Future<void> signOutFirebaseOnly() async {
    _profileFetchedForFirebaseUid = null;
    await _firebaseAuth.signOut();
  }

  /// Sign out: Firebase Auth signOut on device + clear local session. No backend call.
  Future<void> signOut() async {
    _profileFetchedForFirebaseUid = null;
    await _firebaseAuth.signOut();
    await _session.clearSession();
    await _favoritesHiveStore.clear();
  }

}
