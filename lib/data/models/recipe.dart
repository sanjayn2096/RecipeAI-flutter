import 'nutritional_value.dart';

/// Recipe model.
///
/// [recipeId] — unique string per recipe (from model / prompt; API may use `recipeId` or `recipe_id`).
/// [image] — populated from API `imageUrl` or `image`.
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
    final id = json['recipeId'] ?? json['recipe_id'];
    return Recipe(
      recipeId: id is String ? id : (id?.toString() ?? ''),
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

  /// POST save-favorites: backends/Firestore often expect `imageUrl`; only sending `image`
  /// leaves `imageUrl` as JavaScript `undefined` and Firestore throws.
  Map<String, dynamic> toJsonForSaveFavorite() {
    final safeImage = image.trim();
    return {
      'recipeId': recipeId,
      'recipeName': recipeName,
      'image': safeImage,
      'imageUrl': safeImage,
      'ingredients': ingredients,
      'instructions': instructions,
      'cookingTime': cookingTime,
      'cuisine': cuisine,
      'nutritionalValue': nutritionalValue.toJsonForSaveFavorite(),
      'isFavorite': isFavorite,
    };
  }

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
