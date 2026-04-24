import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_strings.dart';
import '../../core/firestore_paths.dart';
import '../api/api_service.dart';
import '../firestore/favorites_firestore_mapper.dart';
import '../local/favorites_hive_store.dart';
import '../models/recipe.dart';
import '../models/api_dtos.dart';
import '../models/session_profile.dart';
import '../../services/session_manager.dart';

/// User data and favorites. Fix: ViewModels use repository instead of API directly.
class UserRepository {
  UserRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
    required FavoritesHiveStore favoritesHiveStore,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _api = apiService,
        _session = sessionManager,
        _favoritesHiveStore = favoritesHiveStore,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiService _api;
  final SessionManager _session;
  final FavoritesHiveStore _favoritesHiveStore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// `users/{userId}/{favoritesSubcollection}` — live updates when Firestore changes.
  Stream<List<Recipe>> watchFavoritesFromFirestore(String userId) {
    return _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(userId)
        .collection(FirestorePaths.favoritesSubcollection)
        .snapshots()
        .map(FavoritesFirestoreMapper.recipesFromQuerySnapshot);
  }

  /// Synchronous read from opened Hive box (called from UI isolate after startup).
  List<Recipe>? readCachedFavoritesSync() =>
      _favoritesHiveStore.readForUserSync(_session.getUserId());

  Future<void> writeCachedFavorites(List<Recipe> recipes) async {
    final id = _session.getUserId();
    if (id == null || id.isEmpty) return;
    await _favoritesHiveStore.write(id, recipes);
  }

  Future<void> clearFavoritesCache() => _favoritesHiveStore.clear();

  /// Fields last saved from GET get_user_profile (also updated on login / session restore).
  SessionProfile readSessionProfile() {
    return SessionProfile(
      userId: _session.getUserId(),
      email: _session.getStoredEmail() ?? '',
      firstName: _session.getFirstName() ?? '',
      lastName: _session.getLastName() ?? '',
    );
  }

  Future<void> saveFavoriteRecipe(Recipe recipe) async {
    final userId = _session.getUserId();
    if (userId == null) return;
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    await _api.saveFavoriteRecipes(
      SaveFavoriteRecipesRequest(recipes: recipe, userId: userId),
      idToken: idToken,
    );
  }

  /// Merges recipe fields (including AI image URLs) into Firestore `recipes/{id}` without changing favorites.
  Future<void> mergeRecipeDocument(Recipe recipe) async {
    final userId = _session.getUserId();
    if (userId == null) return;
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    await _api.saveFavoriteRecipes(
      SaveFavoriteRecipesRequest(
        recipes: recipe,
        userId: userId,
        mergeRecipeImages: true,
      ),
      idToken: idToken,
    );
  }

  /// GET fetch-favorites with Firebase ID token.
  Future<List<Recipe>> fetchFavorites() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    return _api.fetchFavorites(idToken: token);
  }

  /// GET get-recipe/:recipeId with Firebase ID token.
  Future<Recipe> fetchRecipeById(String recipeId) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    return _api.getRecipe(recipeId, idToken: token);
  }

  /// PATCH user-lifestyle from local session prefs (no-op for guests / no token).
  Future<void> syncLifestyleFromPrefs() async {
    if (_session.isGuestMode()) return;
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    try {
      final usual = _session.getUsualCuisines();
      final cuisine = _session.getCuisine() ?? '';
      final merged = <String>{...usual};
      final c = cuisine.trim();
      if (c.isNotEmpty &&
          c != 'No Cuisine Selected' &&
          c != AppStrings.surpriseMe) {
        merged.add(c);
      }
      await _api.patchUserLifestyle(
        UpdateUserLifestyleRequest(
          dietRestrictions: _session.getDietRestrictions(),
          cookingPreference: _session.getCookingPreference(),
          mood: _session.getMood(),
          preferredCuisines: merged.toList(),
        ),
        idToken: token,
      );
    } catch (_) {}
  }

  /// POST suggest-prompts — empty when guest or signed out.
  Future<List<PromptSuggestionItem>> fetchPromptSuggestions({
    String? clientRequestId,
  }) async {
    if (_session.isGuestMode()) return [];
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return [];
    final resp = await _api.suggestPrompts(
      idToken: token,
      clientRequestId: clientRequestId,
    );
    return resp.suggestions;
  }
}
