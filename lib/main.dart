import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/telemetry/api_call_context.dart';
import 'core/telemetry/app_telemetry.dart';
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

Future<void> _initCrashlytics() async {
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = (details) {
    if (kDebugMode) {
      debugPrint('[FlutterError] ${details.exception}');
      debugPrint(details.stack?.toString() ?? '');
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[main] Firebase.initializeApp failed: $e');
      debugPrint(st.toString());
    }
    runApp(_ErrorApp(
      message:
          'Firebase init failed. On iOS, add GoogleService-Info.plist to ios/Runner/ and run flutterfire configure.',
    ));
    return;
  }

  await _initCrashlytics();

  try {
    await Hive.initFlutter();
    final favoritesBox = await FavoritesHiveStore.openBox();
    final favoritesHiveStore = FavoritesHiveStore(favoritesBox);

    final prefs = await SharedPreferences.getInstance();
    final sessionManager = SessionManager(prefs: prefs);

    final analytics = FirebaseAnalytics.instance;
    final appTelemetry = AppTelemetry(analytics);

    final apiService = ApiService(
      getCallContext: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          return ApiCallContext(
            actorId: user.uid,
            actorType: ApiActorType.firebaseUser,
          );
        }
        final anon = await sessionManager.getOrCreateAnonymousId();
        return ApiCallContext(
          actorId: anon,
          actorType: ApiActorType.anonymous,
        );
      },
      onApiCompleted: appTelemetry.logApiCall,
    );
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
      appTelemetry: appTelemetry,
    );
    final homeViewModel = HomeViewModel(
      userRepository: userRepo,
      authRepository: authRepo,
      sessionManager: sessionManager,
      appTelemetry: appTelemetry,
    );
    final recipeViewModel = RecipeViewModel(
      recipeRepository: recipeRepo,
      userRepository: userRepo,
      appTelemetry: appTelemetry,
    );

    final router = AppRouter(
      loginViewModel: loginViewModel,
      homeViewModel: homeViewModel,
      recipeViewModel: recipeViewModel,
      sessionManager: sessionManager,
      analytics: analytics,
    ).router;

    runApp(RecipeAiApp(
      router: router,
      sessionManager: sessionManager,
      appTelemetry: appTelemetry,
    ));
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
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          final colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(message, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RecipeAiApp extends StatefulWidget {
  const RecipeAiApp({
    super.key,
    required this.router,
    required this.sessionManager,
    required this.appTelemetry,
  });

  final GoRouter router;
  final SessionManager sessionManager;
  final AppTelemetry appTelemetry;

  @override
  State<RecipeAiApp> createState() => _RecipeAiAppState();
}

class _RecipeAiAppState extends State<RecipeAiApp> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    unawaited(widget.appTelemetry.syncUserIdentity(widget.sessionManager));
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(widget.appTelemetry.syncUserIdentity(widget.sessionManager));
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sous Chef',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: widget.router,
    );
  }
}
