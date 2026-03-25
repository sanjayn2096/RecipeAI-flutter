/// Common Indian pantry / grocery labels for the Home screen quick-pick chips.
/// Values must match exactly what we append to the prompt (comma-separated).
abstract class PantryItems {
  PantryItems._();

  static const List<String> common = [
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

  static bool isPantryLabel(String segment) =>
      common.contains(segment.trim());
}
