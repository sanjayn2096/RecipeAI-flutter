import 'package:flutter/material.dart';

import '../widgets/sous_chef_brand.dart';

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
  static const int _minPasswordLength = 6;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _firstNameError;
  String? _lastNameError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearEmailError);
    _passwordController.addListener(_clearPasswordError);
    _firstNameController.addListener(_clearFirstNameError);
    _lastNameController.addListener(_clearLastNameError);
  }

  void _clearEmailError() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _clearPasswordError() {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  void _clearFirstNameError() {
    if (_firstNameError != null) setState(() => _firstNameError = null);
  }

  void _clearLastNameError() {
    if (_lastNameError != null) setState(() => _lastNameError = null);
  }

  bool _isValidEmail(String value) {
    if (value.isEmpty) return false;
    final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return re.hasMatch(value);
  }

  bool _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();

    String? emailErr;
    String? passwordErr;
    String? firstErr;
    String? lastErr;

    if (email.isEmpty) {
      emailErr = 'Enter your email';
    } else if (!_isValidEmail(email)) {
      emailErr = 'Enter a valid email address';
    }

    if (password.isEmpty) {
      passwordErr = 'Enter a password';
    } else if (password.length < _minPasswordLength) {
      passwordErr =
          'Password must be at least $_minPasswordLength characters';
    }

    if (first.isEmpty) firstErr = 'Enter your first name';
    if (last.isEmpty) lastErr = 'Enter your last name';

    final hasErrors = emailErr != null ||
        passwordErr != null ||
        firstErr != null ||
        lastErr != null;

    if (hasErrors) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passwordErr;
        _firstNameError = firstErr;
        _lastNameError = lastErr;
      });
      return false;
    }

    setState(() {
      _emailError = null;
      _passwordError = null;
      _firstNameError = null;
      _lastNameError = null;
    });
    return true;
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearEmailError);
    _passwordController.removeListener(_clearPasswordError);
    _firstNameController.removeListener(_clearFirstNameError);
    _lastNameController.removeListener(_clearLastNameError);
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.loginViewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: constraints.maxWidth,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
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
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least $_minPasswordLength characters',
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
                // Hidden by default (_obscurePassword == true); eye toggles visibility.
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: const OutlineInputBorder(),
                  errorText: _firstNameError,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.givenName],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: const OutlineInputBorder(),
                  errorText: _lastNameError,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.familyName],
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
                onPressed: () async {
                  widget.loginViewModel.clearError();
                  if (!_validateFields()) return;

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
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
