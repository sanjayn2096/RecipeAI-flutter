import 'package:firebase_auth/firebase_auth.dart';

import '../data/api/api_service.dart';

/// Short, user-facing copy for signup/login failures (no stack traces).
String authErrorMessage(Object error) {
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
    case 'network-request-failed':
      return 'Network problem. Check your connection and try again.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'operation-not-allowed':
      return 'Sign-in with email and password is not enabled.';
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
