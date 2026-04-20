/// Turns messy recipe ingredient lines into a short display name plus
/// simple metric/imperial quantities (e.g. 1 L oil, 1 kg rice).
abstract class GroceryIngredientNormalize {
  GroceryIngredientNormalize._();

  /// Result of [normalizeRecipeIngredientLine].
  static const String unitEach = 'each';

  /// Strips tbsp/cups/etc. and assigns a coarse default [quantity] + [unit].
  static NormalizedGroceryLine normalizeRecipeIngredientLine(String raw) {
    var name = _stripMeasurementsAndSizing(raw.trim());
    if (name.isEmpty) {
      name = raw.trim();
    }
    name = _titleCaseWords(name);
    final lower = name.toLowerCase();
    final q = _defaultQuantityUnit(lower);
    return NormalizedGroceryLine(
      displayName: name,
      quantity: q.$1,
      unit: q.$2,
    );
  }

  static String _stripMeasurementsAndSizing(String line) {
    var s = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '');
    for (var round = 0; round < 14; round++) {
      final before = s;
      s = s.replaceFirst(
        RegExp(
          r'^\s*\d+\s*x\s*',
          caseSensitive: false,
        ),
        '',
      );
      s = s.replaceFirst(
        RegExp(
          r'^\s*(\d+/\d+|\d+\.\d+|\d+)\s*[-–]?\s*'
          r'(tbsp|tablespoons?|tsp|teaspoons?|cups?|fl\.?\s*oz|fluid\s*oz|oz|ounces?|'
          r'lb|lbs|pounds?|g|grams?|kg|kilograms?|mg|ml|m[lL]|l|L|liters?|litres?|'
          r'pinch(?:es)?|dash(?:es)?|cloves?|slices?|strips?|sprigs?|bunches?|'
          r'packets?|cans?|bottles?)\b\.?\s*',
          caseSensitive: false,
        ),
        '',
      );
      s = s.replaceFirst(
        RegExp(
          r'^\s*(\d+/\d+|\d+\.\d+|\d+)\s*',
        ),
        '',
      );
      s = s.replaceFirst(
        RegExp(
          r'^\s*(?:of|a|an|the)\s+',
          caseSensitive: false,
        ),
        '',
      );
      if (before == s) break;
    }
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceFirst(RegExp(r'^[,;]\s*'), '');
    return s.trim();
  }

  static String _titleCaseWords(String s) {
    if (s.isEmpty) return s;
    return s.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Returns (quantity, unit) with coarse defaults.
  static (String, String) _defaultQuantityUnit(String nameLower) {
    const liquidHints = [
      'oil',
      'vinegar',
      'sauce',
      'milk',
      'water',
      'juice',
      'broth',
      'stock',
      'cream',
      'syrup',
      'wine',
      'liquor',
      'honey',
      'molasses',
    ];
    const dryBulkHints = [
      'rice',
      'flour',
      'sugar',
      'atta',
      'dal',
      'lentil',
      'oats',
      'semolina',
      'cornmeal',
      'beans',
      'pasta',
      'quinoa',
    ];
    const mlHints = ['extract', 'essence', 'vanilla'];
    const lbHints = [
      'chicken',
      'beef',
      'pork',
      'lamb',
      'turkey',
      'fish',
      'shrimp',
      'prawn',
    ];

    for (final h in liquidHints) {
      if (nameLower.contains(h)) return ('1', 'L');
    }
    for (final h in dryBulkHints) {
      if (nameLower.contains(h)) return ('1', 'kg');
    }
    for (final h in mlHints) {
      if (nameLower.contains(h)) return ('1', 'ml');
    }
    for (final h in lbHints) {
      if (nameLower.contains(h)) return ('1', 'lb');
    }
    return ('1', unitEach);
  }
}

/// Normalized line for grocery storage from a recipe ingredient string.
class NormalizedGroceryLine {
  const NormalizedGroceryLine({
    required this.displayName,
    required this.quantity,
    required this.unit,
  });

  final String displayName;
  final String quantity;
  final String unit;
}
