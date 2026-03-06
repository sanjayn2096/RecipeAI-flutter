import 'package:flutter/material.dart';

import '../core/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.loginViewModel,
    required this.onSignupTap,
  });

  final dynamic loginViewModel;
  final VoidCallback onSignupTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          if (widget.loginViewModel.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.loginViewModel.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await widget.loginViewModel.login(
                _emailController.text.trim(),
                _passwordController.text,
              );
              if (widget.loginViewModel.isLoggedIn && context.mounted) {
                // Navigation handled by parent
              }
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: widget.onSignupTap,
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}
