import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/services/pantry/pantry_grocery_lexicon.dart';
import 'package:recipe_ai/services/pantry/pantry_vision_merge.dart';
import 'package:recipe_ai/services/pantry/pantry_vision_raw.dart';

void main() {
  test('merges labels, OCR, and barcodes into grouped suggestions', () {
    final suggestions = PantryVisionMerge.toSuggestions(
      const PantryVisionRawResult(
        classifications: [
          PantryVisionClassification(identifier: 'milk', confidence: 0.8),
          PantryVisionClassification(identifier: 'refrigerator', confidence: 0.9),
        ],
        regionClassifications: [
          PantryVisionClassification(identifier: 'egg', confidence: 0.7),
        ],
        ocrLines: ['Whole Milk 16 FL OZ'],
        barcodes: ['012345678905'],
      ),
    );

    final names = suggestions.map((s) => s.primaryName).toSet();
    expect(names.contains('Whole Milk'), isTrue);
    expect(names.contains('Eggs'), isTrue);
    expect(names, isNot(contains('Refrigerator')));
    expect(suggestions.length, lessThanOrEqualTo(40));
  });

  test('milk carton OCR collapses variants and filters nutrition sugar line', () {
    expect(
      PantryGroceryLexicon.matchLine('Sugars 12g'),
      isNull,
    );

    final suggestions = PantryVisionMerge.toSuggestions(
      const PantryVisionRawResult(
        classifications: [
          PantryVisionClassification(identifier: 'milk', confidence: 0.85),
        ],
        ocrLines: [
          '2% Milk 16 FL OZ',
          'Milk',
          'Sugars 12g',
        ],
      ),
    );

    expect(suggestions.length, 1);
    final milk = suggestions.first;
    expect(milk.primaryName, '2% Milk');
    expect(milk.alternates, contains('Milk'));
    expect(milk.alternates, isNot(contains('Sugar')));
    expect(milk.unit, 'oz');
  });
}
