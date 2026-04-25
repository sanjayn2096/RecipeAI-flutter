import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/api_dtos.dart';
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

  StreamSubscription<List<Recipe>>? _savedFirestoreSub;

  UserData? _userData;
  UserData? get userData => _userData;

  /// From GET get_user_profile, persisted in [SessionManager] (see [UserRepository.readSessionProfile]).
  SessionProfile _sessionProfile = const SessionProfile();
  SessionProfile get sessionProfile => _sessionProfile;

  bool? _isSignedOut;
  bool? get isSignedOut => _isSignedOut;

  /// Saved: Firestore stream (merged `saved` + legacy `favorites`) + Hive; HTTP when cache is missing.
  List<Recipe> _apiSaved = [];
  List<Recipe> get apiSaved => _apiSaved;
  @Deprecated('Use apiSaved')
  List<Recipe> get apiFavorites => _apiSaved;

  bool _savedLoading = false;
  bool get savedLoading => _savedLoading;
  @Deprecated('Use savedLoading')
  bool get favoritesLoading => _savedLoading;

  List<PromptSuggestionItem> _promptSuggestions = const [];
  List<PromptSuggestionItem> get promptSuggestions => _promptSuggestions;

  bool _promptSuggestionsLoading = false;
  bool get promptSuggestionsLoading => _promptSuggestionsLoading;

  @override
  void dispose() {
    _savedFirestoreSub?.cancel();
    super.dispose();
  }

  void _stopSavedFirestoreSync() {
    _savedFirestoreSub?.cancel();
    _savedFirestoreSub = null;
  }

  void _startSavedFirestoreSync() {
    if (_session.isGuestMode()) return;
    final uid = _userRepo.readSessionProfile().userId;
    if (uid == null || uid.isEmpty) return;

    _savedFirestoreSub?.cancel();
    _savedFirestoreSub =
        _userRepo.watchSavedFromFirestore(uid).listen(
      (list) async {
        _apiSaved = dedupeSavedByRecipeId(list);
        await _userRepo.writeCachedSaved(_apiSaved);
        notifyListeners();
      },
      onError: (Object e, StackTrace _) {
        if (kDebugMode) {
          debugPrint('[HomeViewModel] Firestore saved stream error: $e');
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
      _stopSavedFirestoreSync();
      _promptSuggestions = const [];
      _promptSuggestionsLoading = false;
    } else {
      _startSavedFirestoreSync();
      unawaited(loadPromptSuggestions());
    }
  }

  /// Fresh POST suggest-prompts (e.g. each app open via [loadUserDetails]).
  Future<void> loadPromptSuggestions() async {
    if (_session.isGuestMode()) {
      _promptSuggestions = const [];
      _promptSuggestionsLoading = false;
      notifyListeners();
      return;
    }
    final uid = _userRepo.readSessionProfile().userId;
    if (uid == null || uid.isEmpty) {
      _promptSuggestions = const [];
      _promptSuggestionsLoading = false;
      notifyListeners();
      return;
    }

    _promptSuggestionsLoading = true;
    notifyListeners();
    try {
      await _userRepo.syncLifestyleFromPrefs();
      _promptSuggestions = await _userRepo.fetchPromptSuggestions(
        clientRequestId:
            'open_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeViewModel] loadPromptSuggestions: $e');
      }
      _promptSuggestions = const [];
    }
    _promptSuggestionsLoading = false;
    notifyListeners();
  }

  /// Profile screen: read Email / First / Last name from storage (get_user_profile runs once at auth).
  void loadProfileScreen() {
    _refreshSessionProfileFromStorage();
    notifyListeners();
  }

  /// Firestore/arrayRemove often fails to match stored objects (shape differs), so the server
  /// can end up with duplicate entries for the same [recipeId]. Keep one row per id for UI.
  static List<Recipe> dedupeSavedByRecipeId(List<Recipe> list) {
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

  /// Saved tab: read Hive when present; otherwise GET fetch-saved once.
  Future<void> loadSavedFromApi({bool showLoading = true}) async {
    final profile = _userRepo.readSessionProfile();
    final userId = profile.userId;

    if (showLoading && userId != null && userId.isNotEmpty) {
      final cached = _userRepo.readCachedSavedSync();
      if (cached != null) {
        _apiSaved = dedupeSavedByRecipeId(cached);
        _savedLoading = false;
        notifyListeners();
        return;
      }
    }

    if (showLoading) {
      _savedLoading = true;
      notifyListeners();
    }

    try {
      await _telemetry.logFeatureInteraction(
        featureId: FeatureIds.fetchSaved,
        action: 'load',
      );
      final raw = await _userRepo.fetchSavedRecipes();
      _apiSaved = dedupeSavedByRecipeId(raw);
      if (userId != null && userId.isNotEmpty) {
        await _userRepo.writeCachedSaved(_apiSaved);
      }
    } catch (_) {
      if (_apiSaved.isEmpty) {
        _apiSaved = [];
      }
    }

    if (showLoading) {
      _savedLoading = false;
    }
    notifyListeners();
  }

  /// @nodoc
  @Deprecated('Use loadSavedFromApi')
  Future<void> loadFavoritesFromApi({bool showLoading = true}) =>
      loadSavedFromApi(showLoading: showLoading);

  Future<void> _recoverSavedFromNetwork() async {
    try {
      final raw = await _userRepo.fetchSavedRecipes();
      _apiSaved = dedupeSavedByRecipeId(raw);
      final uid = _userRepo.readSessionProfile().userId;
      if (uid != null && uid.isNotEmpty) {
        await _userRepo.writeCachedSaved(_apiSaved);
      }
      notifyListeners();
    } catch (_) {}
  }

  /// GET get-recipe/:recipeId — full recipe doc for a saved item.
  Future<Recipe> fetchSavedRecipeDetail(String recipeId) async {
    return _userRepo.fetchRecipeById(recipeId);
  }

  /// GET /trending-recipes (for discovery; no auth).
  Future<List<Recipe>> loadTrendingRecipes() async {
    try {
      await _telemetry.logFeatureInteraction(featureId: FeatureIds.openTrending);
      return _userRepo.fetchTrendingRecipes(limit: 30);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HomeViewModel] loadTrendingRecipes: $e');
      }
      return [];
    }
  }

  @Deprecated('Use fetchSavedRecipeDetail')
  Future<Recipe> fetchFavoriteRecipeDetail(String recipeId) =>
      fetchSavedRecipeDetail(recipeId);

  static bool _matchesSavedForRemoval(Recipe r, Recipe dismissed) {
    if (dismissed.recipeId.isNotEmpty) {
      return r.recipeId == dismissed.recipeId;
    }
    return identical(r, dismissed);
  }

  /// Swipe-to-remove: optimistic UI, POST save-favorites; Firestore stream refreshes list.
  Future<bool> removeSavedWithSwipe(Recipe recipe) async {
    _apiSaved = _apiSaved
        .where((r) => !_matchesSavedForRemoval(r, recipe))
        .toList();
    notifyListeners();
    try {
      await _telemetry.logFeatureInteraction(featureId: FeatureIds.removeSaved);
      await _userRepo.saveSavedRecipe(recipe.copyWith(isSaved: false));
      return true;
    } catch (_) {
      await _recoverSavedFromNetwork();
      return false;
    }
  }

  @Deprecated('Use removeSavedWithSwipe')
  Future<bool> removeFavoriteWithSwipe(Recipe recipe) =>
      removeSavedWithSwipe(recipe);

  Future<void> signOut() async {
    _stopSavedFirestoreSync();
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
  /// Clears local session and cache; navigate to login from the caller ([signOut] uses [isSignedOut] instead).
  Future<void> deleteAccountWithPassword(String password) async {
    _stopSavedFirestoreSync();
    await _authRepo.deleteAccountWithPassword(password);
    _sessionProfile = const SessionProfile();
    _userData = null;
    _apiSaved = [];
    notifyListeners();
  }

  /// Google reauth delete. Returns `false` if the user cancelled the Google sheet.
  Future<bool> deleteAccountWithGoogleReauth() async {
    _stopSavedFirestoreSync();
    final ok = await _authRepo.deleteAccountWithGoogleReauth();
    if (!ok) return false;
    _sessionProfile = const SessionProfile();
    _userData = null;
    _apiSaved = [];
    notifyListeners();
    return true;
  }

  void clearSignedOutFlag() {
    _isSignedOut = null;
    notifyListeners();
  }
}
