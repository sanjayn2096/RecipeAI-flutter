import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/core/recipe_parsing.dart';

void main() {
  group('formatIngredientLineForDisplay', () {
    test('splits glued quantities, words, and parentheses', () {
      expect(
        RecipeParsing.formatIngredientLineForDisplay(
          '2SalmonFillets(150gEach)',
        ),
        '2 Salmon Fillets (150 g Each)',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('1BunchAsparagus,Trimmed'),
        '1 Bunch Asparagus, Trimmed',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('2TbspOliveOil'),
        '2 Tbsp Olive Oil',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('1Lemon,Sliced'),
        '1 Lemon, Sliced',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('saltAndBlackPepperToTaste'),
        'salt And Black Pepper To Taste',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('1CupRagiFlourMillet'),
        '1 Cup Ragi Flour Millet',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('1CupRagi(fingerMillet)Flour'),
        '1 Cup Ragi (finger Millet) Flour',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('1/2CupFinelyChoppedOnion'),
        '1/2 Cup Finely Chopped Onion',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('2GreenChilies,FinelyChopped'),
        '2 Green Chilies, Finely Chopped',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('saltToTaste'),
        'salt To Taste',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('waterAsNeeded'),
        'water As Needed',
      );
      expect(
        RecipeParsing.formatIngredientLineForDisplay('oilForCooking'),
        'oil For Cooking',
      );
    });

    test('is idempotent for already spaced lines', () {
      const nice = '2 cups all-purpose flour';
      expect(RecipeParsing.formatIngredientLineForDisplay(nice), nice);
    });
  });
}
