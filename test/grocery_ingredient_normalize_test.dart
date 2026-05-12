import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/core/grocery_ingredient_normalize.dart';

void main() {
  group('GroceryIngredientNormalize shopping names', () {
    test('comma-separated prep yields core item', () {
      expect(
        GroceryIngredientNormalize.normalizeRecipeIngredientLine('Lemon, Juiced')
            .displayName,
        'Lemon',
      );
    });

    test('drops to taste and cross-and descriptors', () {
      expect(
        GroceryIngredientNormalize.normalizeRecipeIngredientLine(
          'Salt and Freshly Ground Pepper to taste',
        ).displayName,
        'Salt and Pepper',
      );
    });

    test('preserves substantive comma variants (kosher)', () {
      final n = GroceryIngredientNormalize.normalizeRecipeIngredientLine(
        'Salt, kosher',
      ).displayName;
      expect(n.toLowerCase(), contains('salt'));
      expect(n.toLowerCase(), contains('kosher'));
    });
  });
}
