import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_error_message.dart';
import '../view_models/home_view_model.dart';
import '../view_models/login_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.homeViewModel,
    required this.loginViewModel,
    required this.onBack,
  });

  final HomeViewModel homeViewModel;
  final LoginViewModel loginViewModel;
  final VoidCallback onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.homeViewModel.loadProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User's Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.homeViewModel,
        builder: (_, __) {
          final p = widget.homeViewModel.sessionProfile;
          if (!p.hasDisplayFields) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No profile details yet. They appear after you sign in.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Email', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(
                p.email.isNotEmpty ? p.email : '—',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text('First Name', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                p.firstName.isNotEmpty ? p.firstName : '—',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text('Last Name', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                p.lastName.isNotEmpty ? p.lastName : '—',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () => _onDeleteAccountTap(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete account'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onDeleteAccountTap(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _DeleteAccountConfirmDialog(),
    );
    if (password == null || !context.mounted) return;

    try {
      await widget.homeViewModel.deleteAccount(password);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(e))),
      );
      return;
    }

    if (!context.mounted) return;
    widget.loginViewModel.setLoggedOut();
    context.go('/login');
  }
}

/// Collects the account password and returns it when the user confirms delete.
class _DeleteAccountConfirmDialog extends StatefulWidget {
  const _DeleteAccountConfirmDialog();

  @override
  State<_DeleteAccountConfirmDialog> createState() => _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState extends State<_DeleteAccountConfirmDialog> {
  final _passwordController = TextEditingController();
  String? _fieldError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final pw = _passwordController.text;
    if (pw.isEmpty) {
      setState(() => _fieldError = 'Enter your password');
      return;
    }
    Navigator.of(context).pop(pw);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This permanently deletes your sign-in and cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _fieldError,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}
