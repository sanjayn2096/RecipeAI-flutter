import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_error_message.dart';
import '../core/diet_allergy_options.dart';
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
  late Set<String> _dietSelections;
  late Set<String> _allergenSelections;
  late TextEditingController _allergyNotesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.homeViewModel.loadProfileScreen();
    _dietSelections = widget.homeViewModel.persistedDietProfiles.toSet();
    _allergenSelections = widget.homeViewModel.persistedAllergensAvoid.toSet();
    _allergyNotesController = TextEditingController(
      text: widget.homeViewModel.persistedAllergyNotes ?? '',
    );
  }

  @override
  void dispose() {
    _allergyNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveLifestyle() async {
    setState(() => _saving = true);
    try {
      await widget.homeViewModel.saveLifestyleProfile(
        dietProfiles: _dietSelections.toList(),
        allergensAvoid: _allergenSelections.toList(),
        allergyNotes: _allergyNotesController.text.trim().isEmpty
            ? null
            : _allergyNotesController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diet and allergy preferences saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleDiet(String value) {
    setState(() {
      if (_dietSelections.contains(value)) {
        _dietSelections.remove(value);
      } else {
        _dietSelections.add(value);
      }
    });
  }

  void _toggleAllergen(String value) {
    setState(() {
      if (_allergenSelections.contains(value)) {
        _allergenSelections.remove(value);
      } else {
        _allergenSelections.add(value);
      }
    });
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
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (!p.hasDisplayFields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Sign in to sync your name and email. You can still set diet and allergy preferences on this device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (p.hasDisplayFields) ...[
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
                  p.firstName.isNotEmpty ? p.firstNameForDisplay : '—',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Text('Last Name', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(
                  p.lastName.isNotEmpty ? p.lastNameForDisplay : '—',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
              ],
              Text(
                'Diet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Select all that apply. These are sent with each recipe request.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DietAllergyOptions.dietMultiSelectOptions
                    .map(
                      (label) => FilterChip(
                        label: Text(label),
                        selected: _dietSelections.contains(label),
                        onSelected: (_) => _toggleDiet(label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Allergies & intolerances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Avoid these ingredients in suggestions. See disclaimer below.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DietAllergyOptions.commonAllergens
                    .map(
                      (label) => FilterChip(
                        label: Text(label),
                        selected: _allergenSelections.contains(label),
                        onSelected: (_) => _toggleAllergen(label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _allergyNotesController,
                decoration: const InputDecoration(
                  labelText: 'Extra notes (optional)',
                  hintText: 'e.g. mild lactose intolerance, cumin allergy',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.65),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Important',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DietAllergyOptions.medicalDisclaimer,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _saveLifestyle,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save diet & allergies'),
              ),
              const SizedBox(height: 28),
              if (p.hasDisplayFields)
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
    if (widget.homeViewModel.deleteAccountUsesGoogleReauth) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete account?'),
          content: Text(
            'You will sign in with Google one more time to confirm. '
            'This permanently deletes your account and cannot be undone.',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Continue with Google'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      try {
        final ok = await widget.homeViewModel.deleteAccountWithGoogleReauth();
        if (!ok) return;
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
      return;
    }

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _DeleteAccountConfirmDialog(),
    );
    if (password == null || !context.mounted) return;

    try {
      await widget.homeViewModel.deleteAccountWithPassword(password);
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
