import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class LoginHandlerScreen extends StatefulWidget {
  const LoginHandlerScreen({super.key, required this.loginViewModel});

  final dynamic loginViewModel;

  @override
  State<LoginHandlerScreen> createState() => _LoginHandlerScreenState();
}

class _LoginHandlerScreenState extends State<LoginHandlerScreen> {
  bool _showSignup = false;

  @override
  void initState() {
    super.initState();
    widget.loginViewModel.addListener(_onViewModelUpdate);
  }

  @override
  void dispose() {
    widget.loginViewModel.removeListener(_onViewModelUpdate);
    super.dispose();
  }

  void _onViewModelUpdate() {
    if (widget.loginViewModel.isLoggedIn && mounted) {
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
