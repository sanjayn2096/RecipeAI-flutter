import 'nutritional_value.dart';

/// Recipe model.
///
/// [recipeId] — unique string per recipe.
/// [image] — populated from API `imageUrl`.
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
    final id = json['recipeId'];
    final rawIngredients = json['ingredients'];
    final rawInstructions = json['instructions'];
    final rawImageUrl = json['imageUrl'];
    return Recipe(
      recipeId: id is String ? id : (id?.toString() ?? ''),
      recipeName: json['recipeName'] as String? ?? '',
      image: rawImageUrl is String ? rawImageUrl : rawImageUrl?.toString() ?? '',
      ingredients: rawIngredients is String
          ? rawIngredients
          : rawIngredients?.toString() ?? '',
      instructions: rawInstructions is String
          ? rawInstructions
          : rawInstructions?.toString() ?? '',
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

  /// Combined text for client-side search across all recipe fields.
  String get searchableText {
    final n = nutritionalValue;
    return [
      recipeId,
      recipeName,
      image,
      ingredients,
      instructions,
      cookingTime,
      cuisine,
      n.calories,
      n.protein,
      n.carbs,
      n.fat,
      n.vitamins,
      n.numberOfServings.toString(),
    ].join(' ');
  }

  /// Empty [query] matches all recipes. Otherwise every whitespace-separated
  /// token must appear somewhere in [searchableText] (case-insensitive).
  bool matchesSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return true;
    final haystack = searchableText.toLowerCase();
    for (final token in trimmed.toLowerCase().split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      if (!haystack.contains(token)) return false;
    }
    return true;
  }
}
