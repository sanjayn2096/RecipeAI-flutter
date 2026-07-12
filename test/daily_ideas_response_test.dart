import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/data/api/api_service.dart';

void main() {
  test('DailyIdeasResponse parses categories and flat recipes', () {
    final resp = DailyIdeasResponse.fromJson({
      'batchId': '2026-07-11',
      'date': '2026-07-11',
      'status': 'ready',
      'slot': 'dinner',
      'categories': [
        {
          'id': 'gym',
          'label': 'Gym fuel',
          'recipe': {
            'recipeId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            'recipeName': 'Protein Bowl',
            'image': 'https://example.com/h.png',
            'ingredients': ['chicken'],
            'instructions': '1. Cook',
            'cookingTime': '20 min',
            'cuisine': 'American',
            'nutritionalValue': {
              'calories': '500',
              'protein': '40g',
              'carbs': '30g',
              'fat': '10g',
              'vitamins': '',
              'numberOfServings': 2,
            },
          },
        },
      ],
      'recipes': [],
      'isFallback': false,
    });

    expect(resp.isReady, isTrue);
    expect(resp.hasDisplayRecipes, isTrue);
    expect(resp.categories, hasLength(1));
    expect(resp.categories.first.label, 'Gym fuel');
    expect(resp.categories.first.recipe.recipeName, 'Protein Bowl');
    expect(resp.recipes, hasLength(1));
  });

  test('DailyIdeasResponse falls back to recipes when categories empty', () {
    final resp = DailyIdeasResponse.fromJson({
      'batchId': 'old',
      'status': 'ready',
      'recipes': [
        {
          'recipeId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          'recipeName': 'Soup',
          'image': '',
          'ingredients': [],
          'instructions': '1. Heat',
          'cookingTime': '10 min',
          'cuisine': 'French',
          'nutritionalValue': {
            'calories': '200',
            'protein': '5g',
            'carbs': '20g',
            'fat': '5g',
            'vitamins': '',
            'numberOfServings': 1,
          },
        },
      ],
    });
    expect(resp.hasDisplayRecipes, isTrue);
    expect(resp.recipes.first.recipeName, 'Soup');
  });
}
