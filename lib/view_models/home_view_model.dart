import 'package:flutter/foundation.dart';

import '../data/models/recipe.dart';
import '../data/models/session_profile.dart';
import '../data/models/user_data.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  })  : _userRepo = userRepository,
        _authRepo = authRepository;

  final UserRepository _userRepo;
  final AuthRepository _authRepo;

  UserData? _userData;
  UserData? get userData => _userData;

  /// From GET get_user_profile, persisted in [SessionManager] (see [UserRepository.readSessionProfile]).
  SessionProfile _sessionProfile = const SessionProfile();
  SessionProfile get sessionProfile => _sessionProfile;

  bool? _isSignedOut;
  bool? get isSignedOut => _isSignedOut;

  /// Favorites from GET fetch-favorites (Favorites tab).
  List<Recipe> _apiFavorites = [];
  List<Recipe> get apiFavorites => _apiFavorites;

  bool _favoritesLoading = false;
  bool get favoritesLoading => _favoritesLoading;

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

  Future<void> loadFavoritesFromApi({bool showLoading = true}) async {
    if (showLoading) {
      _favoritesLoading = true;
      notifyListeners();
    }
    try {
      final raw = await _userRepo.fetchFavorites();
      _apiFavorites = dedupeFavoritesByRecipeId(raw);
    } catch (_) {
      _apiFavorites = [];
    }
    if (showLoading) {
      _favoritesLoading = false;
    }
    notifyListeners();
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

  /// Swipe-to-remove: optimistic UI, then POST save-favorites with [isFavorite] false, then
  /// refetch so local state matches Firestore (avoids drift; dedupe hides duplicate docs).
  Future<bool> removeFavoriteWithSwipe(Recipe recipe) async {
    _apiFavorites = _apiFavorites
        .where((r) => !_matchesFavoriteForRemoval(r, recipe))
        .toList();
    notifyListeners();
    try {
      await _userRepo.saveFavoriteRecipe(recipe.copyWith(isFavorite: false));
      await loadFavoritesFromApi(showLoading: false);
      return true;
    } catch (_) {
      await loadFavoritesFromApi(showLoading: false);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepo.signOut();
      _isSignedOut = true;
    } catch (_) {
      _isSignedOut = false;
    }
    notifyListeners();
  }

  void clearSignedOutFlag() {
    _isSignedOut = null;
    notifyListeners();
  }
}
