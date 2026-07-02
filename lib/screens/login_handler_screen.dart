import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

import '../navigation/post_auth_navigation.dart';
import '../services/session_manager.dart';
import '../view_models/login_view_model.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';

class LoginHandlerScreen extends StatefulWidget {
  const LoginHandlerScreen({
    super.key,
    required this.loginViewModel,
    required this.sessionManager,
    this.openSignup = false,
  });

  final LoginViewModel loginViewModel;
  final SessionManager sessionManager;

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
    if (mounted && widget.loginViewModel.isLoggedIn) {
      unawaited(
        navigateAfterAuthentication(
          context,
          sessionManager: widget.sessionManager,
          loginViewModel: widget.loginViewModel,
        ),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.loginViewModel,
      builder: (_, __) {
        if (widget.loginViewModel.isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(
                navigateAfterAuthentication(
                  context,
                  sessionManager: widget.sessionManager,
                  loginViewModel: widget.loginViewModel,
                ),
              );
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (widget.loginViewModel.needsEmailVerification) {
          return VerifyEmailScreen(
            loginViewModel: widget.loginViewModel,
            sessionManager: widget.sessionManager,
          );
        }
        return Scaffold(
          body: _showSignup
              ? SignupScreen(
                  loginViewModel: widget.loginViewModel,
                  onLoginTap: () => setState(() => _showSignup = false),
                )
              : LoginScreen(
                  loginViewModel: widget.loginViewModel,
                  onSignupTap: () => setState(() => _showSignup = true),
                ),
        );
      },
    );
  }
}
