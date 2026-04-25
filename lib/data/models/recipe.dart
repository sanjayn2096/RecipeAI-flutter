import '../../core/recipe_parsing.dart';
import 'nutritional_value.dart';

/// Recipe model.
///
/// [isSaved] — user's private "Saved" list.
/// [isFavorited] — public heart (used for [favoriteCount] on the server).
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
    this.isSaved = false,
    this.isFavorited = false,
    this.favoriteCount = 0,
    this.stepImageUrls = const [],
  });

  final String recipeId;
  final String recipeName;
  final String image;
  /// One entry per ingredient line from the API (array of strings).
  final List<String> ingredients;
  final String instructions;
  final String cookingTime;
  final String cuisine;
  final NutritionalValue nutritionalValue;
  final bool isSaved;
  final bool isFavorited;
  /// Server-side aggregate; may be 0 if unknown.
  final int favoriteCount;
  /// Per-instruction image URLs (e.g. from AI generation), aligned with [RecipeParsing.parseInstructions].
  final List<String> stepImageUrls;

  /// Backward-compatible alias: previously a single "favorite" meant "saved" only.
  bool get isFavorite => isSaved;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final id = json['recipeId'] ?? json['id'];
    final rawIngredients = json['ingredients'];
    final rawInstructions = json['instructions'];
    final rawImageUrl = json['imageUrl'] ?? json['image'];
    final rawStepUrls = json['stepImageUrls'];
    final saved = json['isSaved'] as bool? ??
        json['isFavorite'] as bool? ??
        false;
    final favorited = json['isFavorited'] as bool? ?? false;
    final fc = json['favoriteCount'];
    final count = fc is int
        ? fc
        : fc is num
            ? fc.toInt()
            : int.tryParse('$fc') ?? 0;
    return Recipe(
      recipeId: id is String ? id : (id?.toString() ?? ''),
      recipeName: json['recipeName'] as String? ?? '',
      image: rawImageUrl is String ? rawImageUrl : rawImageUrl?.toString() ?? '',
      ingredients: RecipeParsing.ingredientsFromJson(rawIngredients),
      instructions: rawInstructions is String
          ? rawInstructions
          : rawInstructions?.toString() ?? '',
      cookingTime: json['cookingTime'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      nutritionalValue: NutritionalValue.fromJson(
        (json['nutritionalValue'] as Map<String, dynamic>?) ?? {},
      ),
      isSaved: saved,
      isFavorited: favorited,
      favoriteCount: count,
      stepImageUrls: rawStepUrls is List
          ? rawStepUrls.map((e) => e.toString()).toList()
          : const [],
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
        'isSaved': isSaved,
        'isFavorite': isSaved,
        'isFavorited': isFavorited,
        'favoriteCount': favoriteCount,
        'stepImageUrls': stepImageUrls,
      };

  /// POST save-favorites: backends expect `isSaved` / `isFavorite` and `imageUrl` alias.
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
      'isSaved': isSaved,
      'isFavorite': isSaved,
      'stepImageUrls': stepImageUrls,
    };
  }

  Recipe copyWith({
    bool? isSaved,
    bool? isFavorited,
    int? favoriteCount,
    String? image,
    List<String>? stepImageUrls,
  }) =>
      Recipe(
        recipeId: recipeId,
        recipeName: recipeName,
        image: image ?? this.image,
        ingredients: ingredients,
        instructions: instructions,
        cookingTime: cookingTime,
        cuisine: cuisine,
        nutritionalValue: nutritionalValue,
        isSaved: isSaved ?? this.isSaved,
        isFavorited: isFavorited ?? this.isFavorited,
        favoriteCount: favoriteCount ?? this.favoriteCount,
        stepImageUrls: stepImageUrls ?? this.stepImageUrls,
      );

  /// Combined text for client-side search across all recipe fields.
  String get searchableText {
    final n = nutritionalValue;
    return [
      recipeId,
      recipeName,
      image,
      ingredients.join(' '),
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
