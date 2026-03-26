import 'package:firebase_auth/firebase_auth.dart';

import '../api/api_service.dart';
import '../models/recipe.dart';
import '../models/api_dtos.dart';
import '../models/session_profile.dart';
import '../../services/session_manager.dart';

/// User data and favorites. Fix: ViewModels use repository instead of API directly.
class UserRepository {
  UserRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
    FirebaseAuth? firebaseAuth,
  })  : _api = apiService,
        _session = sessionManager,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final ApiService _api;
  final SessionManager _session;
  final FirebaseAuth _firebaseAuth;

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
}
