import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../core/preference_options.dart';
import '../../core/firestore_paths.dart';
import '../../core/telemetry/firestore_activity_metrics.dart';
import '../../onboarding/onboarding_session_extension.dart';
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
    FirestoreActivityCallback? onFirestoreActivity,
  })  : _api = apiService,
        _session = sessionManager,
        _savedRecipesHiveStore = savedRecipesHiveStore,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _onFirestoreActivity = onFirestoreActivity;

  final ApiService _api;
  final SessionManager _session;
  final SavedRecipesHiveStore _savedRecipesHiveStore;
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirestoreActivityCallback? _onFirestoreActivity;

  void _logFirestore(FirestoreActivityMetrics metrics) {
    _onFirestoreActivity?.call(metrics);
  }

  Stream<T> _listenWithTelemetry<T>(
    Stream<T> stream, {
    required String collection,
    required int Function(T value) docCount,
  }) {
    if (_onFirestoreActivity == null) return stream;
    return stream.map((value) {
      _logFirestore(
        FirestoreActivityMetrics(
          operation: 'listen_snapshot',
          collection: collection,
          docCount: docCount(value),
        ),
      );
      return value;
    });
  }

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

    final sub1 = _listenWithTelemetry(
      saved.snapshots(),
      collection: 'users/*/saved',
      docCount: (v) => v.docs.length,
    ).listen(
      (v) {
        s = v;
        push();
      },
      onError: controller.addError,
    );
    final sub2 = _listenWithTelemetry(
      legacy.snapshots(),
      collection: 'users/*/favorites',
      docCount: (v) => v.docs.length,
    ).listen(
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
    if (favorited) {
      await mergeRecipeDocument(recipe);
    }
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

  /// Persists structured diet/allergens to session and PATCHes Firestore when signed in.
  Future<void> saveLifestylePreferences({
    required List<String> dietProfiles,
    required List<String> allergensAvoid,
    String? allergyNotes,
  }) async {
    await _session.saveDietProfiles(dietProfiles);
    await _session.saveAllergensAvoid(allergensAvoid);
    await _session.saveAllergyNotes(allergyNotes);
    if (_session.isGuestMode()) return;
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    await _api.patchUserLifestyle(
      UpdateUserLifestyleRequest(
        dietProfiles: dietProfiles,
        allergensAvoid: allergensAvoid,
        allergyNotes: allergyNotes,
      ),
      idToken: token,
    );
  }

  /// Persists onboarding completion to Firestore and local session cache.
  Future<void> markOnboardingComplete() async {
    if (_session.isGuestMode()) return;
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    await _api.patchUserOnboarding(
      PatchUserOnboardingRequest(onboardingComplete: true),
      idToken: token,
    );
    _session.setOnboardingCompleteSync(true);
  }

  /// PATCH user-lifestyle from local session prefs (no-op for guests / no token).
  Future<void> syncLifestyleFromPrefs() async {
    if (_session.isGuestMode()) return;
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    try {
      final usual = _session.getUsualCuisines();
      final cuisine = _session.getLifestyleCuisine();
      final merged = <String>{...usual};
      final c = cuisine.trim();
      if (c.isNotEmpty &&
          !PreferenceOptions.isNoCuisineSelected(c) &&
          !PreferenceOptions.isSurpriseCuisine(c)) {
        merged.add(c);
      }
      await _api.patchUserLifestyle(
        UpdateUserLifestyleRequest(
          dietRestrictions: _session.getLifestyleDietRestrictions(),
          dietProfiles: _session.getDietProfiles(),
          allergensAvoid: _session.getAllergensAvoid(),
          allergyNotes: _session.getAllergyNotes(),
          cookingPreference: _session.getLifestyleCookingPreference(),
          mood: _session.getLifestyleMood(),
          preferredCuisines: merged.toList(),
        ),
        idToken: token,
      );
    } catch (_) {}
  }

  /// GET /latest-recipes — premium subscribers only.
  Future<List<Recipe>> fetchLatestRecipes({int limit = 30}) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) {
      throw ApiException(401, 'Sign in required');
    }
    return _api.fetchLatestRecipes(limit: limit, idToken: token);
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

  /// POST /user-app-open — no-op for guests.
  Future<void> recordAppOpen() async {
    if (_session.isGuestMode()) return;
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    try {
      await _api.postUserAppOpen(idToken: token);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[UserRepository] recordAppOpen failed: $e');
        debugPrint(st.toString());
      }
    }
  }

  /// PATCH /user-timezone from device IANA name (no-op for guests).
  Future<void> syncDeviceTimezone() async {
    if (_session.isGuestMode()) return;
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) return;
    try {
      final iana = (await FlutterTimezone.getLocalTimezone()).trim();
      if (iana.isEmpty) return;
      await _api.patchUserTimezone(timezone: iana, idToken: token);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[UserRepository] syncDeviceTimezone failed: $e');
        debugPrint(st.toString());
      }
    }
  }

  /// GET /daily-ideas — empty when guest, not ready, or signed out.
  Future<DailyIdeasResponse> fetchDailyIdeas({String slot = 'dinner'}) async {
    if (_session.isGuestMode()) {
      return const DailyIdeasResponse(
        batchId: '',
        localDate: '',
        slot: 'dinner',
        status: 'guest',
        recipes: [],
      );
    }
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token == null) {
      return const DailyIdeasResponse(
        batchId: '',
        localDate: '',
        slot: 'dinner',
        status: 'signed_out',
        recipes: [],
      );
    }
    return _api.fetchDailyIdeas(idToken: token, slot: slot);
  }
}
