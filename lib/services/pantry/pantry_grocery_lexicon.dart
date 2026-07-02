import '../../core/pantry_items.dart';

/// Searchable grocery vocabulary for matching OCR text on-device.
abstract class PantryGroceryLexicon {
  PantryGroceryLexicon._();

  static final List<String> _extraTerms = [
    'Whole Milk',
    'Skim Milk',
    '2% Milk',
    'Almond Milk',
    'Oat Milk',
    'Soy Milk',
    'Heavy Cream',
    'Half and Half',
    'Sour Cream',
    'Cream Cheese',
    'Yogurt',
    'Greek Yogurt',
    'Cheese',
    'Mozzarella',
    'Swiss Cheese',
    'Feta',
    'Eggs',
    'Egg Whites',
    'Chicken Breast',
    'Chicken Thighs',
    'Ground Beef',
    'Ground Turkey',
    'Bacon',
    'Sausage',
    'Salmon',
    'Tuna',
    'Shrimp',
    'Bread',
    'Bagels',
    'Tortillas',
    'English Muffins',
    'Cereal',
    'Oatmeal',
    'Granola',
    'Rice',
    'Brown Rice',
    'Quinoa',
    'Pasta',
    'Spaghetti',
    'Penne',
    'Flour',
    'Sugar',
    'Brown Sugar',
    'Honey',
    'Maple Syrup',
    'Salt',
    'Black Pepper',
    'Olive Oil',
    'Vegetable Oil',
    'Canola Oil',
    'Vinegar',
    'Balsamic Vinegar',
    'Soy Sauce',
    'Ketchup',
    'Mustard',
    'Mayonnaise',
    'Hot Sauce',
    'Tomato Sauce',
    'Tomato Paste',
    'Diced Tomatoes',
    'Chicken Broth',
    'Vegetable Broth',
    'Beans',
    'Black Beans',
    'Kidney Beans',
    'Chickpeas',
    'Lentils',
    'Peanut Butter',
    'Jam',
    'Coffee',
    'Tea',
    'Orange Juice',
    'Apple Juice',
    'Water',
    'Sparkling Water',
    'Soda',
    'Wine',
    'Beer',
    'Onion',
    'Red Onion',
    'Garlic',
    'Potato',
    'Sweet Potato',
    'Carrot',
    'Celery',
    'Bell Pepper',
    'Broccoli',
    'Cauliflower',
    'Spinach',
    'Kale',
    'Lettuce',
    'Cucumber',
    'Zucchini',
    'Mushrooms',
    'Tomato',
    'Cherry Tomatoes',
    'Avocado',
    'Lemon',
    'Lime',
    'Apple',
    'Banana',
    'Orange',
    'Strawberries',
    'Blueberries',
    'Grapes',
    'Frozen Vegetables',
    'Frozen Fruit',
    'Ice Cream',
    'Butter',
    'Margarine',
    'Tofu',
    'Hummus',
    'Nuts',
    'Almonds',
    'Walnuts',
    'Chips',
    'Crackers',
    'Cookies',
    'Chocolate',
  ];

  static List<String> get allTerms {
    final set = <String>{...PantryItems.allItems, ..._extraTerms};
    final list = set.toList()..sort((a, b) => a.length.compareTo(b.length));
    return list;
  }

  static final Map<String, String> _normalizedIndex = {
    for (final term in allTerms) _normalize(term): term,
  };

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  /// Nutrition-facts tokens — skip when line looks like a label panel, not a product name.
  static const Set<String> _nutritionNoiseTerms = {
    'sugar',
    'sugars',
    'sodium',
    'calories',
    'calorie',
    'protein',
    'fat',
    'fats',
    'carbohydrate',
    'carbohydrates',
    'fiber',
    'fibre',
    'cholesterol',
    'vitamin',
    'calcium',
    'iron',
    'potassium',
    'trans fat',
    'saturated fat',
  };

  static bool _isNutritionFactsLine(String line) {
    final lower = line.toLowerCase();
    if (RegExp(r'\d+\s*(g|mg|mcg|%|kcal|cal)\b').hasMatch(lower)) return true;
    if (lower.contains('daily value')) return true;
    if (lower.contains('serving size')) return true;
    if (lower.contains('nutrition facts')) return true;
    return false;
  }

  static bool _isNutritionNoiseMatch(String term, String line) {
    final normTerm = _normalize(term);
    if (!_nutritionNoiseTerms.contains(normTerm)) return false;
    return _isNutritionFactsLine(line);
  }

  /// Best lexicon match for [line], or null if nothing plausible.
  static LexiconMatch? matchLine(String line) {
    final trimmed = line.trim();
    if (trimmed.length < 3) return null;

    final normLine = _normalize(trimmed);
    if (normLine.isEmpty) return null;

    // Exact normalized match.
    final exact = _normalizedIndex[normLine];
    if (exact != null) {
      if (_isNutritionNoiseMatch(exact, trimmed)) return null;
      return LexiconMatch(name: exact, confidence: 0.92, source: 'ocr_exact');
    }

    // Single best "contains" match (longest term wins).
    String? best;
    for (final term in allTerms.reversed) {
      final normTerm = _normalize(term);
      if (normTerm.length < 3) continue;
      if (normLine.contains(normTerm)) {
        if (_isNutritionNoiseMatch(term, trimmed)) continue;
        best = term;
        break;
      }
    }
    if (best != null) {
      return LexiconMatch(name: best, confidence: 0.78, source: 'ocr_contains');
    }

    // Fuzzy: term starts with first word of line.
    final firstWord = normLine.split(RegExp(r'\s+')).first;
    if (firstWord.length >= 4) {
      String? fuzzyBest;
      for (final entry in _normalizedIndex.entries) {
        if (entry.key.startsWith(firstWord) || firstWord.startsWith(entry.key)) {
          if (_isNutritionNoiseMatch(entry.value, trimmed)) continue;
          if (fuzzyBest == null || entry.value.length > fuzzyBest.length) {
            fuzzyBest = entry.value;
          }
        }
      }
      if (fuzzyBest != null) {
        return LexiconMatch(
          name: fuzzyBest,
          confidence: 0.55,
          source: 'ocr_fuzzy',
        );
      }
    }

    return null;
  }

  /// Parses quantity/unit hints from packaging OCR when present.
  static ({String quantity, String unit}) parseQuantityHints(String line) {
    final t = line.trim();
    final oz = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:fl\.?\s*oz|fluid\s*oz)',
      caseSensitive: false,
    ).firstMatch(t);
    if (oz != null) {
      return (quantity: oz.group(1) ?? '', unit: 'oz');
    }
    final lb = RegExp(r'(\d+(?:\.\d+)?)\s*(?:lb|lbs|pounds?)', caseSensitive: false)
        .firstMatch(t);
    if (lb != null) {
      return (quantity: lb.group(1) ?? '', unit: 'lb');
    }
    final ml = RegExp(r'(\d+(?:\.\d+)?)\s*(?:ml|mL)', caseSensitive: false)
        .firstMatch(t);
    if (ml != null) {
      return (quantity: ml.group(1) ?? '', unit: 'mL');
    }
    final count = RegExp(r'(\d+)\s*(?:ct|count|pk|pack)', caseSensitive: false)
        .firstMatch(t);
    if (count != null) {
      return (quantity: count.group(1) ?? '', unit: 'each');
    }
    return (quantity: '', unit: '');
  }
}

class LexiconMatch {
  const LexiconMatch({
    required this.name,
    required this.confidence,
    required this.source,
  });

  final String name;
  final double confidence;
  final String source;
}
