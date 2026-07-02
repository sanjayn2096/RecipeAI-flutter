import 'dart:async' show unawaited;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kDebugMode, kIsWeb, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/email_not_verified_exception.dart';
import '../api/api_service.dart';
import '../local/saved_recipes_hive_store.dart';
import '../models/api_dtos.dart';
import '../../onboarding/onboarding_session_extension.dart';
import '../../services/session_manager.dart';

/// Web OAuth client ID from Firebase (Project settings → Your apps → Web client).
/// Passed as [GoogleSignIn.serverClientId] on Android/iOS so the plugin returns an
/// id token. On **web**, Google sign-in uses [FirebaseAuth.signInWithPopup] instead
/// of [google_sign_in], so OAuth redirect URIs stay on Firebase’s handler (avoids
/// `redirect_uri_mismatch` when the app is served from a custom hosting domain).
const String _kGoogleWebClientId =
    '516167677061-ig3llepi6f5jk5jg0ajmcma7ps54ino5.apps.googleusercontent.com';

/// iOS OAuth client (must match [GIDClientID] + URL scheme in ios/Runner/Info.plist).
const String _kGoogleIosClientId =
    '516167677061-k8bqvu71tpq9i3c6ktk8j9fn0k184mvu.apps.googleusercontent.com';

const Duration _kProfileFetchTimeout = Duration(seconds: 30);
const Duration _kFirebaseAuthTimeout = Duration(seconds: 45);

/// Brief pause after the Google account UI closes on Android before Firebase auth.
const Duration _kAndroidGooglePickerSettleDelay = Duration(milliseconds: 300);

void _authLog(String step, [Object? detail]) {
  if (!kDebugMode) return;
  debugPrint('[AuthRepository] $step${detail == null ? '' : ': $detail'}');
}

GoogleSignIn _mobileGoogleSignIn() {
  return GoogleSignIn(
    clientId: (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
        ? _kGoogleIosClientId
        : null,
    serverClientId: _kGoogleWebClientId,
    scopes: const ['email', 'profile'],
  );
}

bool _userSignedInWithOAuth(User user) {
  return user.providerData.any(
    (p) => p.providerId == 'google.com' || p.providerId == 'apple.com',
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
    required SavedRecipesHiveStore savedRecipesHiveStore,
    FirebaseAuth? firebaseAuth,
    this.onProfileLoaded,
  })  : _api = apiService,
        _session = sessionManager,
        _savedRecipesHiveStore = savedRecipesHiveStore,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final ApiService _api;
  final SessionManager _session;
  final SavedRecipesHiveStore _savedRecipesHiveStore;
  final FirebaseAuth _firebaseAuth;

  /// Called after GET get_user_profile is persisted (subscription sync).
  final void Function(Map<String, dynamic>? subscription)? onProfileLoaded;

  /// GET get_user_profile: at most once per signed-in Firebase user while the app is running
  /// (no duplicate calls from Profile or other screens; a new app launch will call again on [checkSession]/login).
  String? _profileFetchedForFirebaseUid;

  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  /// True when a Firebase session exists and the address is not verified.
  bool get hasUnverifiedFirebaseUser {
    final u = _firebaseAuth.currentUser;
    return u != null && !u.emailVerified;
  }

  bool get hasFirebaseUser => _firebaseAuth.currentUser != null;

  /// True if the signed-in user has Google Sign-In linked (use Google reauth to delete).
  bool get currentUserHasGoogleProvider {
    final u = _firebaseAuth.currentUser;
    if (u == null) return false;
    return u.providerData.any((p) => p.providerId == 'google.com');
  }

  /// Waits for Firebase Auth to emit initial persisted state (important on web).
  Future<void> waitForAuthReady() async {
    try {
      await _firebaseAuth.authStateChanges().first.timeout(
        _kFirebaseAuthTimeout,
        onTimeout: () => _firebaseAuth.currentUser,
      );
    } catch (_) {}
  }

  Future<void> _reloadFirebaseUser(User user) async {
    try {
      await user.reload().timeout(_kFirebaseAuthTimeout, onTimeout: () {
        throw Exception(
          'Session reload timed out. Check your internet connection and try again.',
        );
      });
    } catch (e) {
      _authLog('user.reload failed, using cached Firebase user', e);
    }
  }

  Future<void> _fetchAndPersistUserProfileOnce(
    User firebaseUser, {
    bool force = false,
  }) async {
    if (!force && _profileFetchedForFirebaseUid == firebaseUser.uid) {
      return;
    }
    _authLog('fetching user profile');
    final token = await firebaseUser.getIdToken().timeout(
      _kFirebaseAuthTimeout,
      onTimeout: () {
        throw Exception(
          'Could not get an auth token. Check your internet connection and try again.',
        );
      },
    );
    final profile = await _api
        .getUserProfile(idToken: token)
        .timeout(_kProfileFetchTimeout, onTimeout: () {
      throw Exception(
        'Loading your profile timed out. Check your connection and try again.',
      );
    });
    _authLog('user profile loaded', profile.userId);
    await _persistProfileFromResponse(firebaseUser, profile);
    _profileFetchedForFirebaseUid = firebaseUser.uid;
  }

  bool _hasCachedSessionProfile(User user) {
    final backendUserId = _session.getUserId();
    if (backendUserId == null || backendUserId.isEmpty) return false;
    final storedEmail = _session.getStoredEmail()?.trim().toLowerCase();
    if (storedEmail == null || storedEmail.isEmpty) return false;
    final firebaseEmail = user.email?.trim().toLowerCase();
    if (firebaseEmail != null &&
        firebaseEmail.isNotEmpty &&
        storedEmail != firebaseEmail) {
      return false;
    }
    return true;
  }

  bool _sessionAllowedWithoutNetworkReload(User user) {
    if (_userSignedInWithOAuth(user)) return true;
    return user.emailVerified;
  }

  /// Reload Firebase user + GET get_user_profile without blocking splash navigation.
  Future<void> _refreshSessionInBackground() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await _reloadFirebaseUser(user);
      final fresh = _firebaseAuth.currentUser;
      if (fresh == null) return;
      if (!_sessionAllowedWithoutNetworkReload(fresh)) return;
      await _fetchAndPersistUserProfileOnce(fresh);
      _authLog('background session refresh complete');
    } catch (e) {
      _authLog('background session refresh failed', e);
    }
  }

  Future<void> _persistProfileFromResponse(User firebaseUser, UserProfileResponse profile) async {
    final previousUserId = _session.getUserId();
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        previousUserId != profile.userId) {
      _session.clearLifestylePrefsSync();
      _session.clearOnboardingStateSync();
    }

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
    await _session.persistLifestyleFromBackend(
      dietProfiles: profile.dietProfiles,
      allergensAvoid: profile.allergensAvoid,
      preferredCuisines: profile.preferredCuisines,
      allergyNotes: profile.allergyNotes,
      applyAllergyNotes: profile.hasAllergyNotesField,
    );
    _session.setOnboardingCompleteSync(profile.onboardingComplete);
    onProfileLoaded?.call(profile.subscription);
  }

  /// Ensures onboarding routing uses backend state (handles cleared local prefs).
  Future<void> prepareOnboardingRoutingState() async {
    if (_session.isGuestMode()) return;
    if (_session.getOnboardingCompleteSync()) return;

    if (_session.hasExistingLifestyleProfile()) {
      await markOnboardingCompleteOnBackend();
      return;
    }

    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await _fetchAndPersistUserProfileOnce(user, force: true);
    } catch (e) {
      _authLog('onboarding routing profile refresh failed', e);
    }
  }

  Future<void> markOnboardingCompleteOnBackend() async {
    if (_session.isGuestMode()) return;
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    await _api.patchUserOnboarding(
      PatchUserOnboardingRequest(onboardingComplete: true),
      idToken: token,
    );
    _session.setOnboardingCompleteSync(true);
  }

  /// Returns true when a signed-in user may enter the app.
  ///
  /// With a locally cached profile, returns immediately and refreshes Firebase +
  /// GET get_user_profile in the background. Without cache, blocks until profile
  /// is loaded (first launch after sign-in).
  Future<bool> checkSession() async {
    await waitForAuthReady();

    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    if (!_sessionAllowedWithoutNetworkReload(user)) {
      return false;
    }
    if (_hasCachedSessionProfile(user)) {
      _authLog('checkSession fast path (cached profile)');
      if (!_session.getOnboardingCompleteSync()) {
        try {
          await _fetchAndPersistUserProfileOnce(user, force: true);
        } catch (e) {
          _authLog('profile refetch for onboarding failed', e);
          unawaited(_refreshSessionInBackground());
        }
      } else {
        unawaited(_refreshSessionInBackground());
      }
      return true;
    }
    _authLog('checkSession slow path (no cached profile)');
    await _reloadFirebaseUser(user);
    final u = _firebaseAuth.currentUser;
    if (u == null) return false;
    if (!_sessionAllowedWithoutNetworkReload(u)) {
      return false;
    }
    try {
      await _fetchAndPersistUserProfileOnce(u);
      return true;
    } catch (e) {
      _authLog('profile fetch failed on cold start', e);
      if (_userSignedInWithOAuth(u)) {
        await _persistMinimalProfileFromFirebase(u);
        unawaited(_refreshSessionInBackground());
        return true;
      }
      await _firebaseAuth.signOut();
      await _session.clearSession();
      return false;
    }
  }

  Future<void> _persistMinimalProfileFromFirebase(User user) async {
    final displayName = user.displayName?.trim() ?? '';
    String? firstName;
    String? lastName;
    if (displayName.isNotEmpty) {
      final parts = displayName.split(RegExp(r'\s+'));
      firstName = parts.first;
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }
    await _session.persistUserProfile(
      userId: user.uid,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<void> _completeLoginForCurrentUser() async {
    final u = _firebaseAuth.currentUser;
    if (u == null) throw Exception('Login failed');
    if (_userSignedInWithOAuth(u)) {
      await _completeOAuthLogin(u);
      return;
    }
    await u.reload().timeout(_kFirebaseAuthTimeout, onTimeout: () {
      throw Exception(
        'Sign-in timed out. Check your internet connection and try again.',
      );
    });
    final fresh = _firebaseAuth.currentUser;
    if (fresh == null) throw Exception('Login failed');
    if (!fresh.emailVerified) {
      throw EmailNotVerifiedException();
    }
    await _fetchAndPersistUserProfileOnce(fresh);
  }

  /// Google/Apple: skip [User.reload] (often slow/hangs on Android) and hydrate profile.
  Future<void> _completeOAuthLogin(User user) async {
    _authLog('completing OAuth login');
    try {
      await _fetchAndPersistUserProfileOnce(user);
    } catch (e) {
      _authLog('profile fetch failed, using Firebase profile', e);
      await _persistMinimalProfileFromFirebase(user);
      unawaited(_refreshSessionInBackground());
    }
  }

  Future<UserCredential> _signInWithGoogleCredential(
    AuthCredential credential,
  ) async {
    _authLog('calling Firebase signInWithCredential');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Future<void>.delayed(_kAndroidGooglePickerSettleDelay);
    }
    return _firebaseAuth.signInWithCredential(credential).timeout(
      _kFirebaseAuthTimeout,
      onTimeout: () {
        throw Exception(
          'Firebase sign-in timed out. Check your internet connection and try again.',
        );
      },
    );
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
    _authLog('signInWithGoogle start', kIsWeb ? 'web' : defaultTargetPlatform);
    if (kIsWeb) {
      _authLog('opening Google popup');
      final userCred =
          await _firebaseAuth.signInWithPopup(_webGoogleAuthProvider());
      if (userCred.user == null) throw Exception('Login failed');
      _authLog('Firebase popup sign-in ok', userCred.user!.uid);
      await _completeLoginForCurrentUser();
      _authLog('signInWithGoogle complete');
      return true;
    }
    final googleSignIn = _mobileGoogleSignIn();
    _authLog('opening Google account picker');
    final account = await googleSignIn.signIn();
    if (account == null) {
      _authLog('Google sign-in cancelled');
      return false;
    }
    _authLog('Google account selected', account.email);
    final googleAuth = await account.authentication;
    if (googleAuth.idToken == null) {
      throw Exception(
        'Google did not return an ID token. Check Firebase OAuth client setup '
        '(SHA-1 on Android, GIDClientID on iOS).',
      );
    }
    _authLog('Google tokens received');
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final userCred = await _signInWithGoogleCredential(credential);
    if (userCred.user == null) throw Exception('Login failed');
    _authLog('Firebase credential sign-in ok', userCred.user!.uid);
    await _completeOAuthLogin(userCred.user!);
    _authLog('signInWithGoogle complete');
    return true;
  }

  /// Create the Firebase account, send Firebase verification email, then require verified
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
    await _savedRecipesHiveStore.clear();
  }

  Future<void> _clearLocalStateAfterAccountRemoval() async {
    _profileFetchedForFirebaseUid = null;
    await _signOutGoogleSignInPluginIfMobile();
    await _firebaseAuth.signOut();
    await _session.clearSession();
    await _savedRecipesHiveStore.clear();
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
