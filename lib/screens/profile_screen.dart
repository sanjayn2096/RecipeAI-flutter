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
    widget.homeViewModel.loadUserDetails();
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
          final userData = widget.homeViewModel.userData;
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: userData == null
                ? const Center(child: Text('No user data'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${userData.email}'),
                      const SizedBox(height: 8),
                      Text('Name: ${userData.firstName} ${userData.lastName ?? ''}'),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
