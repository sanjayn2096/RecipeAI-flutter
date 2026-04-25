import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_service.dart';
import '../data/local/saved_recipes_hive_store.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/session_manager.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final sessionManagerProvider = Provider<SessionManager>((ref) {
  throw UnimplementedError(
    'SessionManager must be overridden after SharedPreferences is ready',
  );
});

final savedRecipesHiveStoreProvider = Provider<SavedRecipesHiveStore>((ref) {
  throw UnimplementedError(
    'SavedRecipesHiveStore must be overridden after Hive.initFlutter + openBox',
  );
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiService: ref.watch(apiServiceProvider),
    sessionManager: ref.watch(sessionManagerProvider),
    savedRecipesHiveStore: ref.watch(savedRecipesHiveStoreProvider),
  );
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    apiService: ref.watch(apiServiceProvider),
    sessionManager: ref.watch(sessionManagerProvider),
    savedRecipesHiveStore: ref.watch(savedRecipesHiveStoreProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(
    sessionManager: ref.watch(sessionManagerProvider),
    apiService: ref.watch(apiServiceProvider),
  );
});
