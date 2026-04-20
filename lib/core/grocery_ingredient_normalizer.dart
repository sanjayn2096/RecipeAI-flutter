/// Converts raw recipe ingredient lines into a clean display name and
/// shopping-friendly quantity + unit (no exact tbsp/cup amounts).

/// Result of parsing one ingredient line for the grocery list.
class ParsedGroceryLine {
  const ParsedGroceryLine({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  /// Title-cased ingredient name (e.g. "Olive oil").
  final String name;

  /// Whole number as string, typically "1" for list defaults.
  final String quantity;

  /// One of [kg], [g], [L], [mL], [lb], [oz], [each].
  final String unit;
}

/// Heuristic parser — not exhaustive for all natural-language recipes.
abstract class GroceryIngredientNormalizer {
  GroceryIngredientNormalizer._();

  /// Metric mass, volume, imperial mass, and count.
  static const String unitKg = 'kg';
  static const String unitG = 'g';
  static const String unitL = 'L';
  static const String unitMl = 'mL';
  static const String unitLb = 'lb';
  static const String unitOz = 'oz';
  static const String unitEach = 'each';

  static const String _defaultQty = '1';

  /// Parses [rawLine] from a recipe into a minimal shopping line.
  static ParsedGroceryLine parse(String rawLine) {
    final original = rawLine.trim();
    if (original.isEmpty) {
      return const ParsedGroceryLine(
        name: 'Item',
        quantity: _defaultQty,
        unit: unitEach,
      );
    }

    var working = original;
    working = _stripLeadingQuantityAndUnits(working);
    working = working.trim();
    if (working.toLowerCase().startsWith('of ')) {
      working = working.substring(3).trim();
    }

    var name = _titleCase(working.isEmpty ? original : working);
    if (name.isEmpty) {
      name = _titleCase(original);
    }

    final lowerName = name.toLowerCase();
    final lowerOrig = original.toLowerCase();

    final bucket = _bucketFor(lowerName, lowerOrig);
    return ParsedGroceryLine(
      name: name,
      quantity: _defaultQty,
      unit: bucket,
    );
  }

  /// Removes leading numbers, fractions, and common unit words.
  static String _stripLeadingQuantityAndUnits(String s) {
    var t = s.trim();
    for (var i = 0; i < 8; i++) {
      final next = _stripOneToken(t);
      if (next == t) break;
      t = next;
    }
    return t.trim();
  }

  static String _stripOneToken(String t) {
    var s = t.trim();
    if (s.isEmpty) return s;

    // Leading "a " / "an "
    final aAn = RegExp(r'^(a|an)\s+', caseSensitive: false);
    if (aAn.hasMatch(s)) {
      return s.replaceFirst(aAn, '').trim();
    }

    // Number ranges "2-3" or "2 – 3"
    final range = RegExp(r'^\d+\s*[-–]\s*\d+\s*');
    if (range.hasMatch(s)) {
      return s.replaceFirst(range, '').trim();
    }

    // Fractions unicode
    final fracUni = RegExp(r'^[½¼¾⅓⅔]\s*');
    if (fracUni.hasMatch(s)) {
      return s.replaceFirst(fracUni, '').trim();
    }

    // a/b fraction
    final fracSlash = RegExp(r'^\d+\s*/\s*\d+\s*');
    if (fracSlash.hasMatch(s)) {
      return s.replaceFirst(fracSlash, '').trim();
    }

    // Decimal or integer
    final numLead = RegExp(r'^\d+([.,]\d+)?\s*');
    if (numLead.hasMatch(s)) {
      return s.replaceFirst(numLead, '').trim();
    }

    // Unit words (longer phrases first).
    final unitRes = <RegExp>[
      RegExp(r'^tablespoons?\s*', caseSensitive: false),
      RegExp(r'^tbsp\.?\s*', caseSensitive: false),
      RegExp(r'^teaspoons?\s*', caseSensitive: false),
      RegExp(r'^tsp\.?\s*', caseSensitive: false),
      RegExp(r'^cups?\s*', caseSensitive: false),
      RegExp(r'^fluid ounces?\s*', caseSensitive: false),
      RegExp(r'^fl\.?\s*oz\s*', caseSensitive: false),
      RegExp(r'^milliliters?\s*', caseSensitive: false),
      RegExp(r'^millilitres?\s*', caseSensitive: false),
      RegExp(r'^ml\.?\s*', caseSensitive: false),
      RegExp(r'^liters?\s*', caseSensitive: false),
      RegExp(r'^litres?\s*', caseSensitive: false),
      RegExp(r'^kilograms?\s*', caseSensitive: false),
      RegExp(r'^kg\.?\s*', caseSensitive: false),
      RegExp(r'^grams?\s*', caseSensitive: false),
      RegExp(r'^ounces?\s*', caseSensitive: false),
      RegExp(r'^oz\.?\s*', caseSensitive: false),
      RegExp(r'^pounds?\s*', caseSensitive: false),
      RegExp(r'^lbs?\.?\s*', caseSensitive: false),
      RegExp(r'^g\s+'), // "500 g flour" → strip g
      RegExp(r'^l\s+', caseSensitive: false), // "1 l water"
      RegExp(r'^pinches?\s*', caseSensitive: false),
      RegExp(r'^slices?\s*', caseSensitive: false),
      RegExp(r'^cloves?\s*', caseSensitive: false),
      RegExp(r'^stalks?\s*', caseSensitive: false),
      RegExp(r'^sprigs?\s*', caseSensitive: false),
      RegExp(r'^bunches?\s*', caseSensitive: false),
      RegExp(r'^pieces?\s*', caseSensitive: false),
      RegExp(r'^large\s+', caseSensitive: false),
      RegExp(r'^medium\s+', caseSensitive: false),
      RegExp(r'^small\s+', caseSensitive: false),
    ];
    for (final re in unitRes) {
      if (re.hasMatch(s)) {
        return s.replaceFirst(re, '').trim();
      }
    }

    return s;
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Keyword buckets for default shopping units (whole-number list).
  static String _bucketFor(String lowerName, String lowerOriginal) {
    final haystack = '$lowerName $lowerOriginal';

    // Cooking oils, vinegars, liquid fats → 1 L bottle scale
    if (RegExp(
      r'\b(oil|vinegar|wine\b|sherry|brandy|rum\b|liqueur|sesame oil|mustard oil|olive)\b',
    ).hasMatch(haystack)) {
      return unitL;
    }

    // Dairy liquids
    if (RegExp(r'\b(milk|cream\b|buttermilk|kefir)\b').hasMatch(haystack)) {
      return unitL;
    }

    // Broths, juices, water for cooking (large)
    if (RegExp(r'\b(stock|broth|juice|water)\b').hasMatch(haystack)) {
      return unitL;
    }

    // Dry goods / bulk
    if (RegExp(
      r'\b(rice|flour|sugar|salt\b|dal\b|lentil|lentils|atta|besan|semolina|pasta\b|oats?|quinoa|couscous|cornmeal)\b',
    ).hasMatch(haystack)) {
      return unitKg;
    }

    // Small spices / aromatics by count
    if (RegExp(
      r'\b(salt|pepper|spice|powder|masala|herbs?|basil|oregano|thyme|parsley|cilantro|coriander leaves|curry leaves)\b',
    ).hasMatch(haystack)) {
      return unitEach;
    }

    // Meat / fish often bought by weight — use kg as default pack scale
    if (RegExp(
      r'\b(chicken|beef|pork|lamb|fish|shrimp|prawn|paneer|tofu)\b',
    ).hasMatch(haystack)) {
      return unitKg;
    }

    // Vegetables default to each unless clearly bulk
    if (RegExp(
      r'\b(onion|tomato|potato|garlic|ginger|chili|pepper|carrot|celery|leek|mushroom|lime|lemon|avocado|egg)\b',
    ).hasMatch(haystack)) {
      return unitEach;
    }

    return unitEach;
  }
}
