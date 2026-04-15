import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/recipe.dart';
import '../data/models/session_profile.dart';
import '../data/models/user_data.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/session_manager.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required UserRepository userRepository,
    required AuthRepository authRepository,
    required SessionManager sessionManager,
    required AppTelemetry appTelemetry,
  })  : _userRepo = userRepository,
        _authRepo = authRepository,
        _session = sessionManager,
        _telemetry = appTelemetry;

  final UserRepository _userRepo;
  final AuthRepository _authRepo;
  final SessionManager _session;
  final AppTelemetry _telemetry;

  StreamSubscription<List<Recipe>>? _favoritesFirestoreSub;

  UserData? _userData;
  UserData? get userData => _userData;

  /// From GET get_user_profile, persisted in [SessionManager] (see [UserRepository.readSessionProfile]).
  SessionProfile _sessionProfile = const SessionProfile();
  SessionProfile get sessionProfile => _sessionProfile;

  bool? _isSignedOut;
  bool? get isSignedOut => _isSignedOut;

  /// Favorites: Firestore stream + Hive; HTTP only when cache is missing.
  List<Recipe> _apiFavorites = [];
  List<Recipe> get apiFavorites => _apiFavorites;

  bool _favoritesLoading = false;
  bool get favoritesLoading => _favoritesLoading;

  @override
  void dispose() {
    _favoritesFirestoreSub?.cancel();
    super.dispose();
  }

  void _stopFavoritesFirestoreSync() {
    _favoritesFirestoreSub?.cancel();
    _favoritesFirestoreSub = null;
  }

  void _startFavoritesFirestoreSync() {
    if (_session.isGuestMode()) return;
    final uid = _userRepo.readSessionProfile().userId;
    if (uid == null || uid.isEmpty) return;

    _favoritesFirestoreSub?.cancel();
    _favoritesFirestoreSub =
        _userRepo.watchFavoritesFromFirestore(uid).listen(
      (list) async {
        _apiFavorites = dedupeFavoritesByRecipeId(list);
        await _userRepo.writeCachedFavorites(_apiFavorites);
        notifyListeners();
      },
      onError: (Object e, StackTrace _) {
        if (kDebugMode) {
          debugPrint('[HomeViewModel] Firestore favorites stream error: $e');
        }
      },
    );
  }

  void _refreshSessionProfileFromStorage() {
    _sessionProfile = _userRepo.readSessionProfile();
  }

  /// Syncs [sessionProfile] from storage and builds [userData] from it (no fetch-user-details API).
  Future<void> loadUserDetails() async {
    _refreshSessionProfileFromStorage();
    _userData = (_sessionProfile.hasDisplayFields || _sessionProfile.userId != null)
        ? UserData.fromSessionProfile(_sessionProfile)
        : null;
    notifyListeners();

    if (_session.isGuestMode()) {
      _stopFavoritesFirestoreSync();
    } else {
      _startFavoritesFirestoreSync();
    }
  }

  /// Profile screen: read Email / First / Last name from storage (get_user_profile runs once at auth).
  void loadProfileScreen() {
    _refreshSessionProfileFromStorage();
    notifyListeners();
  }

  /// Firestore/arrayRemove often fails to match stored objects (shape differs), so the server
  /// can end up with duplicate entries for the same [recipeId]. Keep one row per id for UI.
  static List<Recipe> dedupeFavoritesByRecipeId(List<Recipe> list) {
    final seen = <String>{};
    final out = <Recipe>[];
    for (final r in list) {
      final key = r.recipeId.isNotEmpty
          ? r.recipeId
          : '${r.recipeName}|${r.cuisine}|${r.cookingTime}';
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(r);
    }
    return out;
  }

  /// Favorites tab: read Hive when present; otherwise GET fetch-favorites once.
  Future<void> loadFavoritesFromApi({bool showLoading = true}) async {
    final profile = _userRepo.readSessionProfile();
    final userId = profile.userId;

    if (showLoading && userId != null && userId.isNotEmpty) {
      final cached = _userRepo.readCachedFavoritesSync();
      if (cached != null) {
        _apiFavorites = dedupeFavoritesByRecipeId(cached);
        _favoritesLoading = false;
        notifyListeners();
        return;
      }
    }

    if (showLoading) {
      _favoritesLoading = true;
      notifyListeners();
    }

    try {
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.fetchFavorites,
        action: 'load',
      );
      final raw = await _userRepo.fetchFavorites();
      _apiFavorites = dedupeFavoritesByRecipeId(raw);
      if (userId != null && userId.isNotEmpty) {
        await _userRepo.writeCachedFavorites(_apiFavorites);
      }
    } catch (_) {
      if (_apiFavorites.isEmpty) {
        _apiFavorites = [];
      }
    }

    if (showLoading) {
      _favoritesLoading = false;
    }
    notifyListeners();
  }

  Future<void> _recoverFavoritesFromNetwork() async {
    try {
      final raw = await _userRepo.fetchFavorites();
      _apiFavorites = dedupeFavoritesByRecipeId(raw);
      final uid = _userRepo.readSessionProfile().userId;
      if (uid != null && uid.isNotEmpty) {
        await _userRepo.writeCachedFavorites(_apiFavorites);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// GET get-recipe/:recipeId — full recipe doc for a favorited item.
  Future<Recipe> fetchFavoriteRecipeDetail(String recipeId) async {
    return _userRepo.fetchRecipeById(recipeId);
  }

  static bool _matchesFavoriteForRemoval(Recipe r, Recipe dismissed) {
    if (dismissed.recipeId.isNotEmpty) {
      return r.recipeId == dismissed.recipeId;
    }
    return identical(r, dismissed);
  }

  /// Swipe-to-remove: optimistic UI, POST save-favorites; Firestore stream refreshes list.
  Future<bool> removeFavoriteWithSwipe(Recipe recipe) async {
    _apiFavorites = _apiFavorites
        .where((r) => !_matchesFavoriteForRemoval(r, recipe))
        .toList();
    notifyListeners();
    try {
      await _telemetry.logFeatureInteraction(featureId: FeatureIds.removeFavorite);
      await _userRepo.saveFavoriteRecipe(recipe.copyWith(isFavorite: false));
      return true;
    } catch (_) {
      await _recoverFavoritesFromNetwork();
      return false;
    }
  }

  Future<void> signOut() async {
    _stopFavoritesFirestoreSync();
    try {
      await _telemetry.logFeatureInteraction(featureId: FeatureIds.signOut);
      await _authRepo.signOut();
      _isSignedOut = true;
    } catch (_) {
      _isSignedOut = false;
    }
    notifyListeners();
  }

  /// Whether delete account should use Google reauth (vs password).
  bool get deleteAccountUsesGoogleReauth => _authRepo.currentUserHasGoogleProvider;

  /// Permanently deletes the Firebase account after password confirmation.
  /// Clears local session and favorites; navigate to login from the caller ([signOut] uses [isSignedOut] instead).
  Future<void> deleteAccountWithPassword(String password) async {
    _stopFavoritesFirestoreSync();
    await _authRepo.deleteAccountWithPassword(password);
    _sessionProfile = const SessionProfile();
    _userData = null;
    _apiFavorites = [];
    notifyListeners();
  }

  /// Google reauth delete. Returns `false` if the user cancelled the Google sheet.
  Future<bool> deleteAccountWithGoogleReauth() async {
    _stopFavoritesFirestoreSync();
    final ok = await _authRepo.deleteAccountWithGoogleReauth();
    if (!ok) return false;
    _sessionProfile = const SessionProfile();
    _userData = null;
    _apiFavorites = [];
    notifyListeners();
    return true;
  }

  void clearSignedOutFlag() {
    _isSignedOut = null;
    notifyListeners();
  }
}
