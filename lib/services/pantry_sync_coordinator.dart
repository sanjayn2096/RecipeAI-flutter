import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../data/repositories/user_repository.dart';
import 'session_manager.dart';

/// Debounced pantry push + periodic fallback + lifecycle flush/pull.
///
/// Cadence: 60s idle debounce after local edits, flush on app pause/detach,
/// 5-minute periodic fallback if still dirty. Pull when local is clean.
class PantrySyncCoordinator with WidgetsBindingObserver {
  PantrySyncCoordinator({
    required SessionManager sessionManager,
    required UserRepository userRepository,
    FirebaseAuth? firebaseAuth,
  })  : _session = sessionManager,
        _userRepo = userRepository,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  static const Duration debounceDelay = Duration(seconds: 60);
  static const Duration fallbackInterval = Duration(minutes: 5);

  final SessionManager _session;
  final UserRepository _userRepo;
  final FirebaseAuth _auth;

  Timer? _debounceTimer;
  Timer? _fallbackTimer;
  StreamSubscription<User?>? _authSub;
  bool _started = false;
  bool _flushInFlight = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _session.pantryDirtyRevision.addListener(_onPantryDirtyRevision);
    _fallbackTimer = Timer.periodic(fallbackInterval, (_) {
      unawaited(flush());
    });
    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null || _session.isGuestMode()) return;
      unawaited(_onSignedIn());
    });
    if (_auth.currentUser != null && !_session.isGuestMode()) {
      unawaited(_onSignedIn());
    }
  }

  void dispose() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _session.pantryDirtyRevision.removeListener(_onPantryDirtyRevision);
    _debounceTimer?.cancel();
    _fallbackTimer?.cancel();
    _authSub?.cancel();
  }

  void _onPantryDirtyRevision() {
    if (!_session.isPantryDirty) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, () {
      unawaited(flush());
    });
  }

  Future<void> _onSignedIn() async {
    if (_session.isPantryDirty) {
      await flush();
      return;
    }
    await pull();
  }

  Future<void> flush() async {
    if (_flushInFlight) return;
    _flushInFlight = true;
    try {
      await _userRepo.flushPantryIfDirty();
    } finally {
      _flushInFlight = false;
    }
  }

  Future<void> pull() => _userRepo.pullPantryIfClean();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(flush());
        break;
      case AppLifecycleState.resumed:
        if (_session.isPantryDirty) {
          unawaited(flush());
        } else {
          unawaited(pull());
        }
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }
}
