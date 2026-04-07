import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../view_models/login_view_model.dart';

const Duration _verifyResumeDebounce = Duration(milliseconds: 400);
const Duration _verifyPollInterval = Duration(seconds: 5);

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.loginViewModel});

  final LoginViewModel loginViewModel;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _checkInFlight = false;
  int _resendSecs = 0;
  Timer? _resendTimer;
  Timer? _pollTimer;
  Timer? _resumeDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.loginViewModel.addListener(_onVm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoVerification(silentWhenStillPending: true);
    });
    _pollTimer = Timer.periodic(_verifyPollInterval, (_) {
      _tryAutoVerification(silentWhenStillPending: true);
    });
  }

  @override
  void dispose() {
    _resumeDebounce?.cancel();
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.loginViewModel.removeListener(_onVm);
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeDebounce?.cancel();
      _resumeDebounce = Timer(_verifyResumeDebounce, () {
        _tryAutoVerification(silentWhenStillPending: true);
      });
    }
  }

  void _onVm() {
    if (!mounted) return;
    if (widget.loginViewModel.isLoggedIn) {
      context.go('/home');
    }
    setState(() {});
  }

  Future<void> _tryAutoVerification({required bool silentWhenStillPending}) async {
    if (!mounted ||
        _checkInFlight ||
        widget.loginViewModel.isLoggedIn ||
        !widget.loginViewModel.needsEmailVerification) {
      return;
    }
    _checkInFlight = true;
    try {
      widget.loginViewModel.clearError();
      await widget.loginViewModel.refreshVerificationAndComplete(
        showNotVerifiedMessage: !silentWhenStillPending,
      );
    } finally {
      if (mounted) {
        setState(() => _checkInFlight = false);
      } else {
        _checkInFlight = false;
      }
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecs = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendSecs--;
        if (_resendSecs <= 0) t.cancel();
      });
    });
  }

  Future<void> _onCheckAgainTap() async {
    setState(() => _busy = true);
    await _tryAutoVerification(silentWhenStillPending: false);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _onResendTap() async {
    setState(() => _busy = true);
    await widget.loginViewModel.resendVerificationEmail();
    if (mounted) {
      setState(() => _busy = false);
      if (widget.loginViewModel.errorMessage == null) {
        _startResendCooldown();
      }
    }
  }

  Future<void> _onSignOutTap() async {
    setState(() => _busy = true);
    await widget.loginViewModel.cancelVerificationAndSignOut();
    if (mounted) {
      setState(() => _busy = false);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.loginViewModel.pendingVerificationEmail ?? '';
    final err = widget.loginViewModel.errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                email.isEmpty
                    ? 'We sent a verification link to your email. Open it, then return to this app—we will continue automatically. Please check Spam folder if you are not able to locate in inbox'
                    : 'We sent a verification link to $email. Open it, then return to this app—we will continue automatically. Please check Spam folder if you are not able to locate in inbox',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Stuck? Try Check again below.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 28),
              OutlinedButton(
                onPressed: (_busy || _checkInFlight) ? null : _onCheckAgainTap,
                child: const Text('Check again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: (_busy || _resendSecs > 0) ? null : _onResendTap,
                child: Text(
                  _resendSecs > 0
                      ? 'Resend email ($_resendSecs s)'
                      : 'Resend email',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _onSignOutTap,
                child: const Text('Use a different account'),
              ),
              if (err != null) ...[
                const SizedBox(height: 20),
                Material(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            err,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
