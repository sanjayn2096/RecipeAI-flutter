import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class LoginHandlerScreen extends StatefulWidget {
  const LoginHandlerScreen({
    super.key,
    required this.loginViewModel,
    this.openSignup = false,
  });

  final dynamic loginViewModel;
  /// When true (e.g. route `extra` from guest flows), show sign-up instead of login.
  final bool openSignup;

  @override
  State<LoginHandlerScreen> createState() => _LoginHandlerScreenState();
}

class _LoginHandlerScreenState extends State<LoginHandlerScreen> {
  late bool _showSignup;

  @override
  void initState() {
    super.initState();
    _showSignup = widget.openSignup;
    widget.loginViewModel.addListener(_onViewModelUpdate);
  }

  @override
  void dispose() {
    widget.loginViewModel.removeListener(_onViewModelUpdate);
    super.dispose();
  }

  void _onViewModelUpdate() {
    // Only leave auth for a real login/signup. Guest mode still shows /login until
    // Continue as guest explicitly navigates home (see LoginScreen).
    if (mounted && widget.loginViewModel.isLoggedIn) {
      context.go('/home');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: widget.loginViewModel,
        builder: (_, __) {
          if (widget.loginViewModel.isLoggedIn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/home');
            });
            return const Center(child: CircularProgressIndicator());
          }
          return _showSignup
              ? SignupScreen(
                  loginViewModel: widget.loginViewModel,
                  onLoginTap: () => setState(() => _showSignup = false),
                )
              : LoginScreen(
                  loginViewModel: widget.loginViewModel,
                  onSignupTap: () => setState(() => _showSignup = true),
                );
        },
      ),
    );
  }
}
