import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_strings.dart';
import '../../core/firestore_paths.dart';
import '../api/api_service.dart';
import '../firestore/favorites_firestore_mapper.dart';
import '../local/saved_recipes_hive_store.dart';
import '../models/recipe.dart';
import '../models/api_dtos.dart';
import '../models/session_profile.dart';
import '../../services/session_manager.dart';

/// User data, saved recipes, and public favorites.
class UserRepository {
  UserRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
    required SavedRecipesHiveStore savedRecipesHiveStore,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _api = apiService,
        _session = sessionManager,
        _savedRecipesHiveStore = savedRecipesHiveStore,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final ApiService _api;
  final SessionManager _session;
  final SavedRecipesHiveStore _savedRecipesHiveStore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// `saved` + legacy `favorites` subcollections (merged, live).
  Stream<List<Recipe>> watchSavedFromFirestore(String userId) {
    final user = _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(userId);
    final saved = user.collection(FirestorePaths.savedSubcollection);
    final legacy = user.collection(FirestorePaths.legacyFavoritesSubcollection);

    final controller = StreamController<List<Recipe>>.broadcast();
    QuerySnapshot<Map<String, dynamic>>? s;
    QuerySnapshot<Map<String, dynamic>>? l;

    void push() {
      controller.add(
        FavoritesFirestoreMapper.mergeSavedAndLegacy(s, l),
      );
    }

    final sub1 = saved.snapshots().listen(
      (v) {
        s = v;
        push();
      },
      onError: controller.addError,
    );
    final sub2 = legacy.snapshots().listen(
      (v) {
        l = v;
        push();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  /// Synchronous read from opened Hive box (called from UI isolate after startup).
  List<Recipe>? readCachedSavedSync() =>
      _savedRecipesHiveStore.readForUserSync(_session.getUserId());

  Future<void> writeCachedSaved(List<Recipe> recipes) async {
    final id = _session.getUserId();
    if (id == null || id.isEmpty) return;
    await _savedRecipesHiveStore.write(id, recipes);
  }

  Future<void> clearSavedCache() => _savedRecipesHiveStore.clear();

  /// Fields last saved from GET get_user_profile (also updated on login / session restore).
  SessionProfile readSessionProfile() {
    return SessionProfile(
      userId: _session.getUserId(),
      email: _session.getStoredEmail() ?? '',
      firstName: _session.getFirstName() ?? '',
      lastName: _session.getLastName() ?? '',
    );
  }

  /// POST /save-favorites — updates private Saved list and optional `recipes` doc.
  Future<void> saveSavedRecipe(Recipe recipe) async {
    final userId = _session.getUserId();
    if (userId == null) return;
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    await _api.saveFavoriteRecipes(
      SaveFavoriteRecipesRequest(recipes: recipe, userId: userId),
      idToken: idToken,
    );
  }

  /// Merges recipe fields (including AI image URLs) into Firestore `recipes/{id}` without changing save/favorite.
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

  /// POST /toggle-public-favorite.
  Future<void> togglePublicFavorite(Recipe recipe, {required bool favorited}) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    await _api.togglePublicFavorite(
      recipeId: recipe.recipeId,
      favorited: favorited,
      idToken: token,
    );
  }

  /// GET fetch-saved (merges with legacy `favorites` on the server).
  Future<List<Recipe>> fetchSavedRecipes() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    return _api.fetchSavedRecipes(idToken: token);
  }

  /// GET get-recipe/:recipeId with Firebase ID token.
  Future<Recipe> fetchRecipeById(String recipeId) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    return _api.getRecipe(recipeId, idToken: token);
  }

  Future<List<Recipe>> fetchTrendingRecipes({int limit = 20}) {
    return _api.fetchTrendingRecipes(limit: limit);
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
