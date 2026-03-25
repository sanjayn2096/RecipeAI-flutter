import 'package:flutter/material.dart';

import '../view_models/home_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.homeViewModel,
    required this.onBack,
  });

  final HomeViewModel homeViewModel;
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
            ],
          );
        },
      ),
    );
  }
}
