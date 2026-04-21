import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/email_not_verified_exception.dart';
import '../api/api_service.dart';
import '../local/favorites_hive_store.dart';
import '../models/api_dtos.dart';
import '../../services/session_manager.dart';

/// Web OAuth client ID from Firebase (Project settings → Your apps → Web client).
/// Passed as [GoogleSignIn.serverClientId] on Android/iOS so the plugin returns an
/// id token. On **web**, Google sign-in uses [FirebaseAuth.signInWithPopup] instead
/// of [google_sign_in], so OAuth redirect URIs stay on Firebase’s handler (avoids
/// `redirect_uri_mismatch` when the app is served from a custom hosting domain).
const String _kGoogleWebClientId =
    '516167677061-ig3llepi6f5jk5jg0ajmcma7ps54ino5.apps.googleusercontent.com';

GoogleSignIn _mobileGoogleSignIn() {
  return GoogleSignIn(
    serverClientId: _kGoogleWebClientId,
    scopes: const ['email', 'profile'],
  );
}

Future<void> _signOutGoogleSignInPluginIfMobile() async {
  if (kIsWeb) return;
  try {
    await _mobileGoogleSignIn().signOut();
  } catch (_) {}
}

GoogleAuthProvider _webGoogleAuthProvider() {
  final p = GoogleAuthProvider();
  p.addScope('email');
  p.addScope('profile');
  return p;
}

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

  /// True if the signed-in user has Google Sign-In linked (use Google reauth to delete).
  bool get currentUserHasGoogleProvider {
    final u = _firebaseAuth.currentUser;
    if (u == null) return false;
    return u.providerData.any((p) => p.providerId == 'google.com');
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

  Future<void> _completeLoginForCurrentUser() async {
    final u = _firebaseAuth.currentUser;
    if (u == null) throw Exception('Login failed');
    await u.reload();
    final fresh = _firebaseAuth.currentUser;
    if (fresh == null) throw Exception('Login failed');
    if (!fresh.emailVerified) {
      throw EmailNotVerifiedException();
    }
    await _fetchAndPersistUserProfileOnce(fresh);
  }

  /// Sign in with Firebase, then fetch user profile from backend (GET get_user_profile).
  Future<void> login(String email, String password) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) throw Exception('Login failed');
    await _completeLoginForCurrentUser();
  }

  /// Google Sign-In, then same profile hydration as [login].
  /// Returns `false` if the user closed the Google account picker without signing in.
  Future<bool> signInWithGoogle() async {
    if (kIsWeb) {
      final userCred =
          await _firebaseAuth.signInWithPopup(_webGoogleAuthProvider());
      if (userCred.user == null) throw Exception('Login failed');
      await _completeLoginForCurrentUser();
      return true;
    }
    final googleSignIn = _mobileGoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) {
      return false;
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _firebaseAuth.signInWithCredential(credential);
    if (userCred.user == null) throw Exception('Login failed');
    await _completeLoginForCurrentUser();
    return true;
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
    await _signOutGoogleSignInPluginIfMobile();
  }

  /// Sign out: Firebase Auth signOut on device + clear local session. No backend call.
  Future<void> signOut() async {
    _profileFetchedForFirebaseUid = null;
    await _firebaseAuth.signOut();
    await _signOutGoogleSignInPluginIfMobile();
    await _session.clearSession();
    await _favoritesHiveStore.clear();
  }

  Future<void> _clearLocalStateAfterAccountRemoval() async {
    _profileFetchedForFirebaseUid = null;
    await _signOutGoogleSignInPluginIfMobile();
    await _firebaseAuth.signOut();
    await _session.clearSession();
    await _favoritesHiveStore.clear();
  }

  /// Re-authenticates with email/password, deletes the Firebase user, then clears local session
  /// and favorites (same cleanup as [signOut]).
  Future<void> deleteAccountWithPassword(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'Not signed in.');
    }
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'This account type cannot be deleted here.',
      );
    }
    final credential = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
    await user.delete();
    await _clearLocalStateAfterAccountRemoval();
  }

  /// Re-authenticates with Google, deletes the Firebase user, then clears local state.
  /// Returns `false` if the user closed the Google picker without signing in.
  Future<bool> deleteAccountWithGoogleReauth() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-current-user', message: 'Not signed in.');
    }
    if (kIsWeb) {
      await user.reauthenticateWithPopup(_webGoogleAuthProvider());
      await user.delete();
      await _clearLocalStateAfterAccountRemoval();
      return true;
    }
    final googleSignIn = _mobileGoogleSignIn();
    final account = await googleSignIn.signIn();
    if (account == null) {
      return false;
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
    await user.delete();
    await _clearLocalStateAfterAccountRemoval();
    return true;
  }

}
