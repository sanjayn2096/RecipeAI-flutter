import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../view_models/login_view_model.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.loginViewModel});

  final LoginViewModel loginViewModel;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;
  int _resendSecs = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    widget.loginViewModel.addListener(_onVm);
  }

  @override
  void dispose() {
    widget.loginViewModel.removeListener(_onVm);
    _resendTimer?.cancel();
    super.dispose();
  }

  void _onVm() {
    if (!mounted) return;
    if (widget.loginViewModel.isLoggedIn) {
      context.go('/home');
    }
    setState(() {});
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

  Future<void> _onVerifiedTap() async {
    setState(() => _busy = true);
    widget.loginViewModel.clearError();
    await widget.loginViewModel.refreshVerificationAndComplete();
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
                    ? 'We sent a verification link to your email. Open it, then tap the button below.'
                    : 'We sent a verification link to $email. Open it, then tap the button below.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy ? null : _onVerifiedTap,
                child: const Text("I've verified"),
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
