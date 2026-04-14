import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/sous_chef_brand.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.loginViewModel});

  final dynamic loginViewModel;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) debugPrint('[SplashScreen] initState: adding listener, calling checkSession()');
    widget.loginViewModel.addListener(_onUpdate);
    widget.loginViewModel.checkSession();
  }

  @override
  void dispose() {
    widget.loginViewModel.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (!mounted) return;
    if (widget.loginViewModel.isLoading) return;
    widget.loginViewModel.removeListener(_onUpdate);
    if (kDebugMode) {
      debugPrint(
        '[SplashScreen] _onUpdate: isLoggedIn=${widget.loginViewModel.isLoggedIn}, '
        'isGuest=${widget.loginViewModel.isGuestMode}, navigating',
      );
    }
    if (widget.loginViewModel.needsEmailVerification) {
      context.go('/verify-email');
    } else if (widget.loginViewModel.isLoggedIn ||
        widget.loginViewModel.isGuestMode) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SousChefSplashContent(),
          ),
        ),
      ),
    );
  }
}
