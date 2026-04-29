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
  SaveFavoriteRecipesRequest({
    required this.recipes,
    required this.userId,
    this.mergeRecipeImages = false,
  });
  final Recipe recipes;
  final String userId;

  /// When true, POST /save-favorites only merges into `recipes/{recipeId}` (no favorite add/remove).
  final bool mergeRecipeImages;

  Map<String, dynamic> toJson() => {
        'recipes': recipes.toJsonForSaveFavorite(),
        'userId': userId,
        if (mergeRecipeImages) 'mergeRecipeImages': true,
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
    this.dietProfiles = const [],
    this.allergensAvoid = const [],
    this.allergyNotes,
    this.anonymousId,
    this.excludeRecipeNames = const [],
    this.userRefinementNote,
    this.generationAttempt,
  });

  final List<String> ingredients;
  final String customPreference;
  final String mood;
  final String dietRestrictions;
  final String cuisine;
  final String cookingPreference;
  final RecipeGenerationMode recipeMode;
  /// Structured diet tags (e.g. Vegan, Keto); server merges with signed-in profile when empty.
  final List<String> dietProfiles;
  final List<String> allergensAvoid;
  final String? allergyNotes;
  final String? anonymousId;
  /// Titles already shown; server instructs model not to trivially repeat them.
  final List<String> excludeRecipeNames;
  /// Optional hint for refresh / “more recipes” prompts.
  final String? userRefinementNote;
  /// 1 = first batch from this flow; 2+ = follow-ups (temperature/prompt branching on server).
  final int? generationAttempt;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      'ingredients': ingredients,
      'customPreference': customPreference,
      'mood': mood,
      'dietRestrictions': dietRestrictions,
      'cuisine': cuisine,
      'cookingPreference': cookingPreference,
      'recipeMode': recipeMode.wireName,
      'dietProfiles': dietProfiles,
      'allergensAvoid': allergensAvoid,
    };
    final notes = allergyNotes?.trim();
    if (notes != null && notes.isNotEmpty) {
      m['allergyNotes'] = notes;
    }
    if (anonymousId != null && anonymousId!.trim().isNotEmpty) {
      m['anonymousId'] = anonymousId!.trim();
    }
    if (excludeRecipeNames.isNotEmpty) {
      m['excludeRecipeNames'] = excludeRecipeNames;
    }
    final ref = userRefinementNote?.trim();
    if (ref != null && ref.isNotEmpty) {
      m['userRefinementNote'] = ref;
    }
    if (generationAttempt != null) {
      m['generationAttempt'] = generationAttempt!;
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
        recipes: json
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

/// PATCH /user-lifestyle — omit fields you do not want to change.
class UpdateUserLifestyleRequest {
  UpdateUserLifestyleRequest({
    this.dietRestrictions,
    this.dietProfiles,
    this.allergensAvoid,
    this.allergyNotes,
    this.cookingPreference,
    this.healthGoal,
    this.mood,
    this.preferredCuisines,
  });

  final String? dietRestrictions;
  final List<String>? dietProfiles;
  final List<String>? allergensAvoid;
  final String? allergyNotes;
  final String? cookingPreference;
  final String? healthGoal;
  final String? mood;
  final List<String>? preferredCuisines;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (dietRestrictions != null) m['dietRestrictions'] = dietRestrictions;
    if (dietProfiles != null) m['dietProfiles'] = dietProfiles;
    if (allergensAvoid != null) m['allergensAvoid'] = allergensAvoid;
    if (allergyNotes != null) m['allergyNotes'] = allergyNotes;
    if (cookingPreference != null) m['cookingPreference'] = cookingPreference;
    if (healthGoal != null) m['healthGoal'] = healthGoal;
    if (mood != null) m['mood'] = mood;
    if (preferredCuisines != null) m['preferredCuisines'] = preferredCuisines;
    return m;
  }
}

class PromptSuggestionItem {
  PromptSuggestionItem({required this.text, this.subtitle});
  final String text;
  final String? subtitle;

  factory PromptSuggestionItem.fromJson(Map<String, dynamic> json) {
    return PromptSuggestionItem(
      text: (json['text'] ?? '').toString(),
      subtitle: json['subtitle'] as String?,
    );
  }
}

class SuggestPromptsResponse {
  SuggestPromptsResponse({required this.suggestions});
  final List<PromptSuggestionItem> suggestions;

  factory SuggestPromptsResponse.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    final list = map['suggestions'] as List<dynamic>? ?? [];
    return SuggestPromptsResponse(
      suggestions: list
          .whereType<Map<String, dynamic>>()
          .map(PromptSuggestionItem.fromJson)
          .where((s) => s.text.trim().isNotEmpty)
          .toList(),
    );
  }
}

/// Response from GET get_user_profile (used after Firebase sign-in).
class UserProfileResponse {
  UserProfileResponse({
    required this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.dietProfiles,
    this.allergensAvoid,
    this.allergyNotes,
    this.hasAllergyNotesField = false,
  });
  final String userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  /// Present when GET user document includes structured fields (`null` = omit key — do not wipe local prefs).
  final List<String>? dietProfiles;
  final List<String>? allergensAvoid;
  final String? allergyNotes;
  final bool hasAllergyNotesField;

  static List<String> _stringList(dynamic v) {
    if (v is! List) return const [];
    return v
        .map((e) => e?.toString() ?? '')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    final uid = json['userId'] ?? json['user_id'];
    String? pickStr(String a, String b) {
      final v = json[a] ?? json[b];
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    }

    final bool hasAllergyNotesField = json.containsKey('allergyNotes');
    String? allergyNotes;
    if (hasAllergyNotesField) {
      final raw = json['allergyNotes'];
      allergyNotes = raw == null ? '' : raw.toString().trim();
    }

    return UserProfileResponse(
      userId: uid is String ? uid : uid?.toString() ?? '',
      email: json['email'] as String?,
      firstName: pickStr('firstName', 'first_name'),
      lastName: pickStr('lastName', 'last_name'),
      dietProfiles:
          json.containsKey('dietProfiles') ? _stringList(json['dietProfiles']) : null,
      allergensAvoid: json.containsKey('allergensAvoid')
          ? _stringList(json['allergensAvoid'])
          : null,
      allergyNotes: allergyNotes,
      hasAllergyNotesField: hasAllergyNotesField,
    );
  }
}
