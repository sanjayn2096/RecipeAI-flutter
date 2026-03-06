/// Nutritional info for a recipe.
class NutritionalValue {
  const NutritionalValue({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.vitamins,
    required this.numberOfServings,
  });

  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final String vitamins;
  final int numberOfServings;

  factory NutritionalValue.fromJson(Map<String, dynamic> json) {
    return NutritionalValue(
      calories: json['calories'] as String? ?? 'N/A',
      protein: json['protein'] as String? ?? 'N/A',
      carbs: json['carbs'] as String? ?? 'N/A',
      fat: json['fat'] as String? ?? 'N/A',
      vitamins: json['vitamins'] as String? ?? 'N/A',
      numberOfServings: json['numberOfServings'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'vitamins': vitamins,
        'numberOfServings': numberOfServings,
      };
}
