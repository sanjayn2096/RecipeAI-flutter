import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/core/grocery_ingredient_normalizer.dart';

void main() {
  group('GroceryIngredientNormalizer', () {
    test('strips tbsp and titles name', () {
      final p = GroceryIngredientNormalizer.parse('2 tbsp olive oil');
      expect(p.name, 'Olive Oil');
      expect(p.quantity, '1');
      expect(p.unit, GroceryIngredientNormalizer.unitL);
    });

    test('strips cup measure for dry good → kg', () {
      final p = GroceryIngredientNormalizer.parse('1 cup basmati rice');
      expect(p.name, 'Basmati Rice');
      expect(p.unit, GroceryIngredientNormalizer.unitKg);
    });

    test('bare noun uses fallback bucket', () {
      final p = GroceryIngredientNormalizer.parse('garlic');
      expect(p.name, 'Garlic');
      expect(p.unit, GroceryIngredientNormalizer.unitEach);
    });

    test('metric line strips g token', () {
      final p = GroceryIngredientNormalizer.parse('500 g paneer');
      expect(p.name, 'Paneer');
      expect(p.unit, GroceryIngredientNormalizer.unitKg);
    });
  });
}
