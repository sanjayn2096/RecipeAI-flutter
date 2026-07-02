import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/monetization_config.dart';
import '../navigation/post_auth_navigation.dart';
import '../services/mobile_ads_initializer.dart';
import '../services/session_manager.dart';
import '../view_models/login_view_model.dart';
import '../widgets/sous_chef_brand.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.loginViewModel,
    required this.sessionManager,
  });

  final LoginViewModel loginViewModel;
  final SessionManager sessionManager;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _fallbackTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
        '[SplashScreen] initState: adding listener, calling checkSession()',
      );
    }
    widget.loginViewModel.addListener(_onUpdate);
    unawaited(widget.loginViewModel.checkSession());
    _fallbackTimer = Timer(const Duration(seconds: 20), _onFallbackTimeout);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    widget.loginViewModel.removeListener(_onUpdate);
    super.dispose();
  }

  void _onFallbackTimeout() {
    if (!mounted || _navigated) return;
    if (kDebugMode) {
      debugPrint('[SplashScreen] fallback timeout — routing to login');
    }
    _navigateOnce(() => context.go('/login'));
  }

  void _navigateOnce(void Function() navigate) {
    if (!mounted || _navigated) return;
    _navigated = true;
    _fallbackTimer?.cancel();
    widget.loginViewModel.removeListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigate();
    });
  }

  Future<void> _navigateAfterAuth() {
    return navigateAfterAuthentication(
      context,
      sessionManager: widget.sessionManager,
      loginViewModel: widget.loginViewModel,
    );
  }

  void _onUpdate() {
    if (!mounted || _navigated) return;
    if (widget.loginViewModel.isLoading) return;
    if (kDebugMode) {
      debugPrint(
        '[SplashScreen] _onUpdate: isLoggedIn=${widget.loginViewModel.isLoggedIn}, '
        'isGuest=${widget.loginViewModel.isGuestMode}, navigating',
      );
    }
    if (widget.loginViewModel.needsEmailVerification) {
      _navigateOnce(() => context.go('/verify-email'));
    } else if (widget.loginViewModel.isLoggedIn ||
        widget.loginViewModel.isGuestMode) {
      if (MonetizationConfig.adsEnabled) {
        unawaited(MobileAdsInitializer.ensureInitialized());
      }
      _navigateOnce(() => unawaited(_navigateAfterAuth()));
    } else {
      _navigateOnce(() => context.go('/login'));
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
