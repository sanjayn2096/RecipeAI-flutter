import 'preference_options.dart';

/// Canonical multi-select options for profile (diet styles + common allergens).
class DietAllergyOptions {
  DietAllergyOptions._();

  static List<String> get dietMultiSelectOptionKeys =>
      PreferenceOptions.dietMultiSelectKeys;

  static List<String> get commonAllergenKeys => PreferenceOptions.allergenKeys;
}
