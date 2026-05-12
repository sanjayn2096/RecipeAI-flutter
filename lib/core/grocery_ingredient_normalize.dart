import 'grocery_ingredient_display.dart';

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
    name = _stripForShopping(name);
    name = _titleCaseIngredientLabel(name);
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

  /// Removes prep wording, modality phrases ("to taste"), and trims descriptors
  /// so grocery rows read like plain shopping items ("Lemon" not "Lemon, Juiced").
  static String _stripForShopping(String name) {
    var s =
        name.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (s.isEmpty) return name.trim();
    s = _stripTrailingModalitySuffixes(s);
    s = _stripCommaPrepRhs(s);
    s = _stripTrailingModalitySuffixes(s);

    final andSplit = RegExp(r'\s+and\s+', caseSensitive: false);
    if (andSplit.hasMatch(s)) {
      final parts = s
          .split(andSplit)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        final cleaned = <String>[];
        for (final p in parts) {
          var seg = _stripTrailingModalitySuffixes(p);
          seg = _stripCommaPrepRhs(seg);
          seg = _stripTrailingModalitySuffixes(seg);
          final core = GroceryIngredientDisplay.shoppingCorePhrase(seg);
          if (core.isNotEmpty) cleaned.add(core);
        }
        return cleaned.join(' and ');
      }
    }

    s = _stripCommaPrepRhs(s);
    s = _stripTrailingModalitySuffixes(s);
    return GroceryIngredientDisplay.shoppingCorePhrase(s);
  }

  static final RegExp _trailingModality = RegExp(
    r'[,;]?\s*(to\s+taste|as\s+needed|as\s+desired|to\s+serve|optional|'
    r'for\s+garnish|for\s+serving|for\s+dusting|for\s+sprinkling)\s*$',
    caseSensitive: false,
  );

  static String _stripTrailingModalitySuffixes(String s) {
    var t = s.trim();
    for (var i = 0; i < 6; i++) {
      final next = t.replaceFirst(_trailingModality, '').trim();
      if (next == t) break;
      t = next;
    }
    return t;
  }

  /// Words allowed after the first comma when the RHS is purely prep/descriptor,
  /// e.g. `Lemon, Juiced`, `Parsley, Chopped Fine`.
  static const _commaRhsPrepLexicon = <String>{
    'minced',
    'chopped',
    'diced',
    'sliced',
    'shredded',
    'grated',
    'crushed',
    'peeled',
    'trimmed',
    'juiced',
    'zested',
    'halved',
    'quartered',
    'seeded',
    'thawed',
    'mashed',
    'smashed',
    'frozen',
    'melted',
    'warm',
    'warmed',
    'softened',
    'thinly',
    'roughly',
    'finely',
    'thickly',
    'coarsely',
    'fresh',
    'freshly',
    'lightly',
    'packed',
    'heaping',
    'divided',
    'cold',
    'room',
    'temperature',
    'optional',
    'ground',
    'whole',
    'cooked',
    'raw',
    'boneless',
    'skinless',
    'fine',
    'coarse',
  };

  static String _stripCommaPrepRhs(String s) {
    final idx = s.indexOf(',');
    if (idx <= 0) return s;
    final lhs = s.substring(0, idx).trim();
    var rhs = s.substring(idx + 1).trim();
    if (lhs.isEmpty || rhs.isEmpty) return s;
    if (_trailingModality.hasMatch(rhs)) {
      return lhs;
    }
    final normRhs = rhs.toLowerCase().replaceAll(RegExp(r'[,;/]'), ' ');
    final tokens = normRhs
        .split(RegExp(r'\s+'))
        .map((t) => t.replaceAll(RegExp(r'[^\w]'), ''))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return lhs;
    for (final t in tokens) {
      if (!_commaRhsPrepLexicon.contains(t)) return s;
    }
    return lhs;
  }

  static String _titleCaseIngredientLabel(String s) {
    if (s.isEmpty) return s;
    const small = {'and', 'or', '&'};
    return s.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      final lower = w.toLowerCase();
      if (small.contains(lower)) return lower;
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
