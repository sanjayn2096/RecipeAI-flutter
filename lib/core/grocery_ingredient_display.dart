/// Short label for list rows: core ingredient only (e.g. "Garlic" from "Minced Garlic").
abstract class GroceryIngredientDisplay {
  GroceryIngredientDisplay._();

  static const _leadingDescriptors = <String>{
    'minced',
    'chopped',
    'diced',
    'grated',
    'sliced',
    'shredded',
    'crushed',
    'peeled',
    'trimmed',
    'boneless',
    'skinless',
    'fresh',
    'dried',
    'frozen',
    'canned',
    'organic',
    'large',
    'small',
    'medium',
    'fine',
    'coarse',
    'optional',
    'cold-pressed',
    'extra',
    'virgin',
    'light',
    'dark',
    'brown',
    'white',
    'black',
    'sweet',
    'sour',
    'unsalted',
    'salted',
    'ground',
    'whole',
    'cooked',
    'raw',
    'about',
    'approx',
    'plus',
  };

  static const _trailingCountNouns = <String>{
    'cloves',
    'clove',
    'slices',
    'slice',
    'strips',
    'strip',
    'pieces',
    'piece',
    'sticks',
    'stick',
    'bunches',
    'bunch',
    'sprigs',
    'sprig',
    'leaves',
    'leaf',
    'heads',
    'head',
    'ears',
    'ear',
    'spears',
    'spear',
    'pearls',
  };

  /// Title shown in the grocery list for a stored [name] (already normalized).
  static String listTitle(String storedName) {
    final words = _baseWords(storedName);
    if (words.isEmpty) {
      return storedName.trim();
    }
    return words.map(_titleCaseWord).join(' ');
  }

  /// Base ingredient phrase in lowercase used for matching (e.g. "green onion").
  static String baseIngredientKey(String name) {
    final words = _baseWords(name);
    if (words.isEmpty) return name.trim().toLowerCase();
    return words.map((w) => w.toLowerCase()).join(' ');
  }

  static List<String> _baseWords(String value) {
    var words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    while (words.length > 1 &&
        _leadingDescriptors.contains(words.first.toLowerCase())) {
      words = words.sublist(1);
    }
    while (words.length > 1 &&
        _trailingCountNouns.contains(words.last.toLowerCase())) {
      words = words.sublist(0, words.length - 1);
    }
    return words;
  }

  static String _titleCaseWord(String w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }
}
