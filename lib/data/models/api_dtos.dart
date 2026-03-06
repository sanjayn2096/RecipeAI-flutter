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
        'recipes': recipes.toJson(),
        'userId': userId,
      };
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
