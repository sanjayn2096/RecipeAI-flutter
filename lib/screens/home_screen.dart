import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_strings.dart';
import '../data/models/user_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.homeViewModel,
    required this.recipeViewModel,
    required this.sessionManager,
  });

  final dynamic homeViewModel;
  final dynamic recipeViewModel;
  final dynamic sessionManager;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _customPreferenceController;

  @override
  void initState() {
    super.initState();
    _customPreferenceController = TextEditingController(
      text: widget.sessionManager.getPreference('customPreference') ?? '',
    );
    widget.homeViewModel.addListener(_onUpdate);
    widget.homeViewModel.loadUserDetails();
  }

  @override
  void dispose() {
    _customPreferenceController.dispose();
    widget.homeViewModel.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (widget.homeViewModel.isSignedOut == true && mounted) {
      widget.homeViewModel.clearSignedOutFlag();
      context.go('/login');
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.homeViewModel,
      builder: (_, __) {
        final userData = widget.homeViewModel.userData;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.push('/profile'),
              ),
              IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: () => context.push('/favorites'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => widget.homeViewModel.signOut(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    if (userData != null)
                      Text(
                        'Hello, ${userData.firstName}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (userData != null) const SizedBox(height: 32),
                    Text(
                      AppStrings.letsCookSomethingNice,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _customPreferenceController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.whatDoYouFeelLikeEating,
                        border: OutlineInputBorder(),
                        hintText: 'e.g. something light, pasta, curry',
                      ),
                      onChanged: (value) {
                        widget.sessionManager.savePreferenceSync(
                          'customPreference',
                          value.trim(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.push('/recipe-flow', extra: userData),
                      icon: const Icon(Icons.restaurant),
                      label: const Text('Create Recipes'),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
