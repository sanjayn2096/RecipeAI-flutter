import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/data/models/api_dtos.dart';
import 'package:recipe_ai/data/models/nutritional_value.dart';
import 'package:recipe_ai/data/models/recipe.dart';

void main() {
  const recipe = Recipe(
    recipeId: 'recipe-1',
    recipeName: 'Lemon Herb Salmon',
    image: '',
    ingredients: ['2 salmon fillets', '1 lemon'],
    instructions: 'Bake at 400F until flaky.',
    cookingTime: '25 minutes',
    cuisine: 'Mediterranean',
    nutritionalValue: NutritionalValue(
      calories: '420 kcal',
      protein: '34g',
      carbs: '6g',
      fat: '28g',
      vitamins: 'Vitamin D',
      numberOfServings: 2,
    ),
  );

  test('RecipeQuestionRequest serializes recipe and conversation', () {
    const request = RecipeQuestionRequest(
      recipe: recipe,
      question: 'Can I use lime?',
      conversation: [
        RecipeAssistantMessageDto(
          role: 'assistant',
          content: 'Use fresh lemon if possible.',
        ),
      ],
    );

    final json = request.toJson();

    expect(json['question'], 'Can I use lime?');
    expect(json['recipe'], isA<Map<String, dynamic>>());
    expect((json['recipe'] as Map<String, dynamic>)['recipeName'],
        'Lemon Herb Salmon');
    expect(json['conversation'], [
      {'role': 'assistant', 'content': 'Use fresh lemon if possible.'},
    ]);
  });

  test('RecipeQuestionResponse parses guardrail response', () {
    final response = RecipeQuestionResponse.fromJson({
      'answer': 'I can only help with questions about this recipe.',
      'outOfContext': true,
      'suggestedFollowUps': ['How long should I bake it?', 'Can I meal prep it?'],
    });

    expect(response.outOfContext, isTrue);
    expect(response.answer, 'I can only help with questions about this recipe.');
    expect(response.suggestedFollowUps, [
      'How long should I bake it?',
      'Can I meal prep it?',
    ]);
  });
}
