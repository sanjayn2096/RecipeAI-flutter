import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.loginViewModel,
    required this.onLoginTap,
  });

  final dynamic loginViewModel;
  final VoidCallback onLoginTap;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
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
              await widget.loginViewModel.signup(
                email: _emailController.text.trim(),
                password: _passwordController.text,
                firstName: _firstNameController.text.trim(),
                lastName: _lastNameController.text.trim(),
              );
              if (widget.loginViewModel.isLoggedIn && context.mounted) {}
            },
            child: const Text('Sign up'),
          ),
          TextButton(
            onPressed: widget.onLoginTap,
            child: const Text('Already have an account? Log in'),
          ),
        ],
      ),
    );
  }
}
