import '../api/api_service.dart';
import '../models/user_data.dart';
import '../models/recipe.dart';
import '../models/api_dtos.dart';
import '../../services/session_manager.dart';

/// User data and favorites. Fix: ViewModels use repository instead of API directly.
class UserRepository {
  UserRepository({
    required ApiService apiService,
    required SessionManager sessionManager,
  })  : _api = apiService,
        _session = sessionManager;

  final ApiService _api;
  final SessionManager _session;

  Future<UserData?> getUserDetails() async {
    final email = _session.getEmail();
    if (email == null) return null;
    try {
      return await _api.fetchUserDetails(email);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveFavoriteRecipe(Recipe recipe) async {
    final userId = _session.getUserId();
    if (userId == null) return;
    await _api.saveFavoriteRecipes(
      SaveFavoriteRecipesRequest(recipes: recipe, userId: userId),
    );
  }
}
