import 'recipe.dart';

// --- Request DTOs ---

class LoginRequest {
  LoginRequest({required this.email, required this.tokenId});
  final String email;
  final String tokenId;
  Map<String, dynamic> toJson() => {'email': email, 'token_id': tokenId};
}

class SessionCheckRequest {
  SessionCheckRequest({required this.sessionId});
  final String sessionId;
  Map<String, dynamic> toJson() => {'sessionId': sessionId};
}

class SignupRequest {
  SignupRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });
  final String email, password, firstName, lastName;
  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      };
}

class SignoutRequest {
  SignoutRequest({required this.email});
  final String email;
  Map<String, dynamic> toJson() => {'email': email};
}

class SaveFavoriteRecipesRequest {
  SaveFavoriteRecipesRequest({required this.recipes, required this.userId});
  final Recipe recipes;
  final String userId;
  Map<String, dynamic> toJson() => {
        'recipes': recipes.toJsonForSaveFavorite(),
        'userId': userId,
      };
}

/// Stable wire value for POST /generate-recipe (avoids coupling "feeling lucky" to UI copy).
enum RecipeGenerationMode {
  custom('custom'),
  lucky('lucky'),
  preferences('preferences');

  const RecipeGenerationMode(this.wireName);
  final String wireName;
}

/// Body for POST generate-recipe. Server builds the LLM prompt from these fields.
class GenerateRecipeRequest {
  GenerateRecipeRequest({
    required this.ingredients,
    required this.customPreference,
    required this.mood,
    required this.dietRestrictions,
    required this.cuisine,
    required this.cookingPreference,
    required this.recipeMode,
    this.anonymousId,
  });

  final List<String> ingredients;
  final String customPreference;
  final String mood;
  final String dietRestrictions;
  final String cuisine;
  final String cookingPreference;
  final RecipeGenerationMode recipeMode;
  final String? anonymousId;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'ingredients': ingredients,
      'customPreference': customPreference,
      'mood': mood,
      'dietRestrictions': dietRestrictions,
      'cuisine': cuisine,
      'cookingPreference': cookingPreference,
      'recipeMode': recipeMode.wireName,
    };
    if (anonymousId != null && anonymousId!.trim().isNotEmpty) {
      m['anonymousId'] = anonymousId!.trim();
    }
    return m;
  }
}

// --- Response DTOs ---

class LoginResponse {
  LoginResponse({this.message, this.userId});
  final String? message;
  final String? userId;
  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        message: json['message'] as String?,
        userId: json['userId'] as String?,
      );
}

class SessionCheckResponse {
  SessionCheckResponse({this.message, this.userId});
  final String? message;
  final String? userId;
  factory SessionCheckResponse.fromJson(Map<String, dynamic> json) =>
      SessionCheckResponse(
        message: json['message'] as String?,
        userId: json['userId'] as String?,
      );
}

class SignupResponse {
  SignupResponse({this.message, this.userId});
  final String? message;
  final String? userId;
  factory SignupResponse.fromJson(Map<String, dynamic> json) => SignupResponse(
        message: json['message'] as String?,
        userId: json['userId'] as String?,
      );
}

class SignoutResponse {
  SignoutResponse({this.message});
  final String? message;
  factory SignoutResponse.fromJson(Map<String, dynamic> json) =>
      SignoutResponse(message: json['message'] as String?);
}

class SaveFavoriteRecipesResponse {
  SaveFavoriteRecipesResponse({this.message});
  final String? message;
  factory SaveFavoriteRecipesResponse.fromJson(Map<String, dynamic> json) =>
      SaveFavoriteRecipesResponse(message: json['message'] as String?);
}

/// Response from POST generate-recipe. Backend may return { "recipes": [...] } or array.
class GenerateRecipeResponse {
  GenerateRecipeResponse({required this.recipes});
  final List<Recipe> recipes;
  factory GenerateRecipeResponse.fromJson(dynamic json) {
    if (json is List) {
      return GenerateRecipeResponse(
        recipes: (json as List)
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    final map = json as Map<String, dynamic>;
    final list = map['recipes'] as List<dynamic>? ?? map['recipe'] as List<dynamic>? ?? [];
    return GenerateRecipeResponse(
      recipes: list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Response from GET get_user_profile (used after Firebase sign-in).
class UserProfileResponse {
  UserProfileResponse({required this.userId, this.email, this.firstName, this.lastName});
  final String userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final uid = json['userId'] ?? json['user_id'];
    String? pickStr(String a, String b) {
      final v = json[a] ?? json[b];
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    return UserProfileResponse(
      userId: uid is String ? uid : uid?.toString() ?? '',
      email: json['email'] as String?,
      firstName: pickStr('firstName', 'first_name'),
      lastName: pickStr('lastName', 'last_name'),
    );
  }
}
