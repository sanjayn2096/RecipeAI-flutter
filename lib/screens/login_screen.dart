import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../view_models/login_view_model.dart';
import '../widgets/sous_chef_brand.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.loginViewModel,
    required this.onSignupTap,
  });

  final LoginViewModel loginViewModel;
  final VoidCallback onSignupTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _googleSigningIn = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onEmailChanged() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _onPasswordChanged() {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  bool _isValidEmail(String value) {
    if (value.isEmpty) return false;
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return re.hasMatch(value);
  }

  /// Returns false if validation failed (field errors set; no API call).
  bool _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailErr;
    String? passwordErr;

    if (email.isEmpty) {
      emailErr = 'Enter your email';
    } else if (!_isValidEmail(email)) {
      emailErr = 'Enter a valid email address';
    }

    if (password.isEmpty) {
      passwordErr = 'Enter your password';
    }

    if (emailErr != null || passwordErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passwordErr;
      });
      return false;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
    });
    return true;
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.loginViewModel,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SousChefLoginHeader(),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  errorText: _emailError,
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submitLogin(context),
              ),
              if (widget.loginViewModel.errorMessage != null) ...[
                const SizedBox(height: 16),
                Material(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withOpacity(0.35),
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
                            widget.loginViewModel.errorMessage!,
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _submitLogin(context),
                child: const Text('Login'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).dividerColor)),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _googleSigningIn
                    ? null
                    : () => _submitGoogleSignIn(context),
                child: _googleSigningIn
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.google,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 10),
                          const Text('Continue with Google'),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: widget.onSignupTap,
                child: const Text('Sign Up with Email'),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                  ),
                  onPressed: () async {
                    widget.loginViewModel.clearError();
                    await widget.loginViewModel.enterGuestMode();
                    if (!context.mounted) return;
                    context.go('/home');
                  },
                  child: const Text('Continue as guest'),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse recipes without an account, Signup To Save favorites.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitLogin(BuildContext context) async {
    if (!_validateFields()) return;

    widget.loginViewModel.clearError();
    await widget.loginViewModel.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (widget.loginViewModel.isLoggedIn && context.mounted) {
      // Navigation handled by parent
    }
  }

  Future<void> _submitGoogleSignIn(BuildContext context) async {
    setState(() => _googleSigningIn = true);
    widget.loginViewModel.clearError();
    await widget.loginViewModel.signInWithGoogle();
    if (mounted) setState(() => _googleSigningIn = false);
  }
}
