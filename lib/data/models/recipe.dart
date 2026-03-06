import 'nutritional_value.dart';

/// Recipe model. API may return `imageUrl`; we map it to [image].
class Recipe {
  const Recipe({
    required this.recipeId,
    required this.recipeName,
    required this.image,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.cuisine,
    required this.nutritionalValue,
    this.isFavorite = false,
  });

  final String recipeId;
  final String recipeName;
  final String image;
  final String ingredients;
  final String instructions;
  final String cookingTime;
  final String cuisine;
  final NutritionalValue nutritionalValue;
  final bool isFavorite;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipeId: json['recipeId'] as String? ?? '',
      recipeName: json['recipeName'] as String? ?? '',
      image: (json['imageUrl'] ?? json['image']) as String? ?? '',
      ingredients: json['ingredients'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      cookingTime: json['cookingTime'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      nutritionalValue: NutritionalValue.fromJson(
        (json['nutritionalValue'] as Map<String, dynamic>?) ?? {},
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'recipeId': recipeId,
        'recipeName': recipeName,
        'image': image,
        'ingredients': ingredients,
        'instructions': instructions,
        'cookingTime': cookingTime,
        'cuisine': cuisine,
        'nutritionalValue': nutritionalValue.toJson(),
        'isFavorite': isFavorite,
      };

  Recipe copyWith({bool? isFavorite}) => Recipe(
        recipeId: recipeId,
        recipeName: recipeName,
        image: image,
        ingredients: ingredients,
        instructions: instructions,
        cookingTime: cookingTime,
        cuisine: cuisine,
        nutritionalValue: nutritionalValue,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
