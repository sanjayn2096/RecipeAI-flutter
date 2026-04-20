/// Allowed units for manual grocery entry (mass, volume, count).
abstract class GroceryUnits {
  GroceryUnits._();

  static const String kg = 'kg';
  static const String g = 'g';
  static const String l = 'L';
  static const String ml = 'mL';
  static const String lb = 'lb';
  static const String oz = 'oz';
  static const String each = 'each';

  static const List<String> all = [kg, g, l, ml, lb, oz, each];
}
