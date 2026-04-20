import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/core/grocery_ingredient_display.dart';

void main() {
  group('GroceryIngredientDisplay.listTitle', () {
    test('drops minced and uses core noun', () {
      expect(
        GroceryIngredientDisplay.listTitle('Minced Garlic'),
        'Garlic',
      );
    });

    test('drops trailing cloves', () {
      expect(
        GroceryIngredientDisplay.listTitle('Garlic Cloves'),
        'Garlic',
      );
    });

    test('keeps multi-word oils', () {
      expect(
        GroceryIngredientDisplay.listTitle('Olive Oil'),
        'Olive Oil',
      );
    });
  });
}
