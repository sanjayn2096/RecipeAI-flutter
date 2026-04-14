import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../data/api/api_service.dart';
import 'email_not_verified_exception.dart';

/// Short, user-facing copy for signup/login failures (no stack traces).
String authErrorMessage(Object error) {
  if (error is EmailNotVerifiedException) {
    return error.message;
  }

  if (error is PlatformException) {
    return _platformMessage(error);
  }

  if (error is ApiException) {
    final msg = error.message.trim();
    if (msg.isEmpty) return _generic;
    if (msg.length > 200) return '${msg.substring(0, 197)}…';
    return msg;
  }

  if (error is FirebaseAuthException) {
    return _firebaseMessage(error);
  }

  if (error is Exception) {
    return _stringFromException(error.toString());
  }

  return _stringFromException(error.toString());
}

/// [Google Sign-In Android: ApiException 10](https://developers.google.com/android/guides/client-auth)
/// means the app’s SHA-1 (and usually SHA-256) is missing or wrong in Firebase for this package name.
String _platformMessage(PlatformException e) {
  final msg = e.message ?? '';
  if (e.code == 'sign_in_failed' && (msg.contains('ApiException: 10') || msg.contains(': 10:'))) {
    return 'Google sign-in: add your debug SHA-1 in Firebase (Project settings → Android app) '
        'and replace android/app/google-services.json. Run: cd android && ./gradlew :app:signingReport';
  }
  // Android USER_CANCELLED (12501); iOS often uses sign_in_canceled
  if (e.code == 'sign_in_canceled' ||
      (e.code == 'sign_in_failed' &&
          (msg.contains('12501') || msg.contains('ApiException: 12501')))) {
    return 'Sign-in was cancelled.';
  }
  if (msg.isNotEmpty && msg.length <= 220) {
    return msg;
  }
  if (msg.length > 220) {
    return '${msg.substring(0, 217)}…';
  }
  return _generic;
}

String _firebaseMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'email-already-in-use':
      return 'This email is already registered. Try logging in instead.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support if you need help.';
    case 'user-not-found':
    case 'wrong-password':
      return 'Incorrect email or password.';
    case 'invalid-credential':
      return 'Invalid email or password. Try again.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with this email using a different sign-in method. Try email and password, or the provider you used before.';
    case 'network-request-failed':
      return 'Network problem. Check your connection and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'operation-not-allowed':
      return 'Sign-in with email and password is not enabled.';
    case 'requires-recent-login':
      return 'For your security, sign in again, then try deleting your account.';
    case 'no-current-user':
      return 'You are not signed in.';
    default:
      final m = e.message?.trim();
      if (m != null && m.isNotEmpty && !m.contains('Instance of')) {
        return m;
      }
      return _generic;
  }
}

String _stringFromException(String raw) {
  var s = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  final idx = s.indexOf('\n');
  if (idx != -1) {
    s = s.substring(0, idx).trim();
  }
  if (s.startsWith('ApiException(')) {
    final match = RegExp(r'ApiException\([^)]*\):\s*(.+)$').firstMatch(s);
    if (match != null) return match.group(1)!.trim();
  }
  if (s.isEmpty) return _generic;
  if (s.length > 200) return '${s.substring(0, 197)}…';
  return s;
}

const _generic = 'Something went wrong. Please try again.';
