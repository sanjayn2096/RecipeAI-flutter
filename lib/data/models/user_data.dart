import 'recipe.dart';

/// User profile and recipe lists from backend.
class UserData {
  const UserData({
    required this.email,
    required this.firstName,
    this.lastName,
    this.favoriteRecipes,
    this.createdRecipes = const [],
  });

  final String email;
  final String firstName;
  final String? lastName;
  final List<Recipe>? favoriteRecipes;
  final List<Recipe> createdRecipes;

  factory UserData.fromJson(Map<String, dynamic> json) {
    final fav = json['favorite_recipes'];
    final created = json['created_recipes'];
    return UserData(
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String?,
      favoriteRecipes: fav == null
          ? null
          : (fav as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList(),
      createdRecipes: created == null
          ? []
          : (created as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'favorite_recipes': favoriteRecipes?.map((e) => e.toJson()).toList(),
        'created_recipes': createdRecipes.map((e) => e.toJson()).toList(),
      };
}
