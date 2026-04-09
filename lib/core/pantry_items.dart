/// Pantry / grocery labels for the Home screen.
///
/// These strings are sent as-is to POST generate-recipe in the `ingredients` list.
/// Keep them user-friendly and stable.
abstract class PantryItems {
  PantryItems._();

  /// Fallback pack if the user hasn't chosen cuisines yet.
  static const String cuisinePopular = 'Popular';

  static const List<String> _indian = [
    'Basmati Rice',
    'Toor Dal',
    'Moong Dal',
    'Chana Dal',
    'Masoor Dal',
    'Urad Dal',
    'Atta',
    'Besan',
    'Rice Flour',
    'Jeera',
    'Haldi',
    'Dhaniya Powder',
    'Garam Masala',
    'Mustard Oil',
    'Ghee',
    'Paneer',
    'Curd',
    'Onion',
    'Tomato',
    'Ginger',
    'Garlic',
    'Green Chili',
    'Coriander',
    'Coconut',
    'Cashew',
    'Tamarind',
    'Jaggery',
    'Curry Leaves',
  ];

  static const List<String> _mexican = [
    'Tortillas',
    'Black Beans',
    'Pinto Beans',
    'Salsa',
    'Cilantro',
    'Lime',
    'Avocado',
    'Cumin',
    'Chili Powder',
    'Cheddar',
    'Onion',
    'Tomato',
    'Garlic',
  ];

  static const List<String> _chinese = [
    'Soy Sauce',
    'Oyster Sauce',
    'Rice Vinegar',
    'Sesame Oil',
    'Cornstarch',
    'Ginger',
    'Garlic',
    'Scallions',
    'Chili Oil',
    'Noodles',
    'Rice',
  ];

  static const List<String> _thai = [
    'Coconut Milk',
    'Fish Sauce',
    'Soy Sauce',
    'Rice',
    'Rice Noodles',
    'Lime',
    'Thai Basil',
    'Cilantro',
    'Garlic',
    'Ginger',
    'Curry Paste',
  ];

  static const List<String> _korean = [
    'Gochujang',
    'Gochugaru',
    'Soy Sauce',
    'Sesame Oil',
    'Rice Vinegar',
    'Garlic',
    'Ginger',
    'Scallions',
    'Kimchi',
    'Rice',
  ];

  static const List<String> _italian = [
    'Olive Oil',
    'Garlic',
    'Onion',
    'Tomato',
    'Basil',
    'Oregano',
    'Parmesan',
    'Pasta',
  ];

  static const List<String> _american = [
    'Eggs',
    'Butter',
    'Milk',
    'Bread',
    'Cheddar',
    'Potato',
    'Onion',
    'Garlic',
  ];

  static const List<String> _popular = [
    'Onion',
    'Tomato',
    'Garlic',
    'Ginger',
    'Rice',
    'Pasta',
    'Eggs',
    'Olive Oil',
    'Butter',
    'Milk',
  ];

  /// Suggested pantry staples grouped by cuisine.
  /// Keys should match the user-facing cuisine strings (e.g. `AppStrings.indian`).
  static const Map<String, List<String>> staplesByCuisine = {
    cuisinePopular: _popular,
    'Indian': _indian,
    'Mexican': _mexican,
    'Chinese': _chinese,
    'Thai': _thai,
    'Korean': _korean,
    'Italian': _italian,
    'American': _american,
  };

  /// Backwards-compatible list used by the chip UI (defaults to the Indian list).
  static List<String> get common => _indian;

  /// Union of all pantry items (for search).
  static List<String> get allItems {
    final set = <String>{};
    for (final items in staplesByCuisine.values) {
      set.addAll(items);
    }
    final list = set.toList()..sort();
    return list;
  }

  static List<String> suggestedForCuisines(List<String> cuisines,
      {int limit = 24}) {
    final set = <String>{};
    final keys = cuisines.isEmpty ? const [cuisinePopular] : cuisines;
    for (final cuisine in keys) {
      set.addAll(staplesByCuisine[cuisine] ?? const []);
    }
    final list = set.toList();
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  static bool isPantryLabel(String segment) =>
      allItems.contains(segment.trim()) || common.contains(segment.trim());
}
