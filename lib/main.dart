import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'data/api/api_service.dart';
import 'data/local/favorites_hive_store.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/recipe_repository.dart';
import 'data/repositories/user_repository.dart';
import 'services/session_manager.dart';
import 'view_models/login_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/recipe_view_model.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.exception}');
      debugPrint(details.stack?.toString() ?? '');
    }
  };

  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[main] Firebase.initializeApp failed: $e');
      debugPrint(st.toString());
    }
    runApp(_ErrorApp(
      message: 'Firebase init failed. On iOS, add GoogleService-Info.plist to ios/Runner/ and run flutterfire configure.',
    ));
    return;
  }

  try {
    await Hive.initFlutter();
    final favoritesBox = await FavoritesHiveStore.openBox();
    final favoritesHiveStore = FavoritesHiveStore(favoritesBox);

    final prefs = await SharedPreferences.getInstance();
    final sessionManager = SessionManager(prefs: prefs);

    final apiService = ApiService();
    final authRepo = AuthRepository(
      apiService: apiService,
      sessionManager: sessionManager,
      favoritesHiveStore: favoritesHiveStore,
    );
    final userRepo = UserRepository(
      apiService: apiService,
      sessionManager: sessionManager,
      favoritesHiveStore: favoritesHiveStore,
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
    final recipeRepo = RecipeRepository(
      sessionManager: sessionManager,
      apiService: apiService,
      firebaseAuth: FirebaseAuth.instance,
    );

    final loginViewModel = LoginViewModel(
      authRepository: authRepo,
      sessionManager: sessionManager,
    );
    final homeViewModel = HomeViewModel(
      userRepository: userRepo,
      authRepository: authRepo,
      sessionManager: sessionManager,
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
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[main] App setup failed: $e');
      debugPrint(st.toString());
    }
    runApp(_ErrorApp(message: '$e'));
  }
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Something went wrong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecipeAiApp extends StatelessWidget {
  const RecipeAiApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sous Chef',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
