import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'data/api/api_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/recipe_repository.dart';
import 'data/repositories/user_repository.dart';
import 'services/remote_config_service.dart';
import 'services/session_manager.dart';
import 'view_models/login_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/recipe_view_model.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final remoteConfig = RemoteConfigService();
  await remoteConfig.initialize();
  final geminiApiKey = remoteConfig.geminiApiKey ?? '';

  final prefs = await SharedPreferences.getInstance();
  final sessionManager = SessionManager(prefs: prefs);

  final apiService = ApiService();
  final authRepo = AuthRepository(
    apiService: apiService,
    sessionManager: sessionManager,
  );
  final userRepo = UserRepository(
    apiService: apiService,
    sessionManager: sessionManager,
  );
  final recipeRepo = RecipeRepository(
    apiKey: geminiApiKey,
    sessionManager: sessionManager,
  );

  final loginViewModel = LoginViewModel(authRepository: authRepo);
  final homeViewModel = HomeViewModel(
    userRepository: userRepo,
    authRepository: authRepo,
  );
  final recipeViewModel = RecipeViewModel(
    recipeRepository: recipeRepo,
    userRepository: userRepo,
  );

  final router = AppRouter(
    loginViewModel: loginViewModel,
    homeViewModel: homeViewModel,
    recipeViewModel: recipeViewModel,
    sessionManager: sessionManager,
  ).router;

  runApp(RecipeAiApp(router: router));
}

class RecipeAiApp extends StatelessWidget {
  const RecipeAiApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RecipeAI',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
