import 'package:recipe_ai/l10n/app_localizations.dart';

/// Stable storage keys for questionnaire / profile options.
///
/// UI shows localized labels; prefs and API use [toApiEnglish] at boundaries.
class PreferenceOptions {
  PreferenceOptions._();

  // --- Mood ---
  static const String moodHappyExcited = 'happy_excited';
  static const String moodSadTired = 'sad_tired';
  static const String moodNotHungry = 'not_hungry';
  static const String moodNeutral = 'neutral';
  static const String moodFeelingLucky = 'feeling_lucky';
  static const String moodAngry = 'angry';
  static const String moodConfused = 'confused';

  static const List<String> moodKeys = [
    moodHappyExcited,
    moodSadTired,
    moodNotHungry,
    moodNeutral,
    moodFeelingLucky,
    moodAngry,
    moodConfused,
  ];

  // --- Diet ---
  static const String dietVegetarian = 'vegetarian';
  static const String dietVegan = 'vegan';
  static const String dietPescitarian = 'pescitarian';
  static const String dietNonVegetarianWithoutRedMeat =
      'non_vegetarian_without_red_meat';
  static const String dietNonVegetarianWithRedMeat =
      'non_vegetarian_with_red_meat';
  static const String dietNutFree = 'nut_free';
  static const String dietPaleo = 'paleo';
  static const String dietKeto = 'keto';
  static const String dietGlutenFree = 'gluten_free';
  static const String dietNoRestrictions = 'no_restrictions';
  static const String dietHalal = 'halal';
  static const String dietKosher = 'kosher';

  static const List<String> dietKeys = [
    dietVegetarian,
    dietVegan,
    dietPescitarian,
    dietNonVegetarianWithoutRedMeat,
    dietNonVegetarianWithRedMeat,
    dietNutFree,
    dietPaleo,
    dietKeto,
    dietGlutenFree,
    dietNoRestrictions,
  ];

  static const List<String> dietMultiSelectKeys = [
    dietVegetarian,
    dietVegan,
    dietPescitarian,
    dietNonVegetarianWithoutRedMeat,
    dietNonVegetarianWithRedMeat,
    dietNutFree,
    dietPaleo,
    dietKeto,
    dietGlutenFree,
    dietHalal,
    dietKosher,
  ];

  // --- Cuisine ---
  static const String cuisineIndian = 'indian';
  static const String cuisineMexican = 'mexican';
  static const String cuisineChinese = 'chinese';
  static const String cuisineThai = 'thai';
  static const String cuisineKorean = 'korean';
  static const String cuisineItalian = 'italian';
  static const String cuisineAmerican = 'american';
  static const String cuisineSurpriseMe = 'surprise_me';
  static const String cuisinePopular = 'popular';

  static const List<String> cuisineKeys = [
    cuisineIndian,
    cuisineMexican,
    cuisineChinese,
    cuisineThai,
    cuisineKorean,
    cuisineItalian,
    cuisineAmerican,
    cuisineSurpriseMe,
  ];

  static const List<String> preferredCuisineKeys = [
    cuisineIndian,
    cuisineMexican,
    cuisineChinese,
    cuisineThai,
    cuisineKorean,
    cuisineItalian,
    cuisineAmerican,
  ];

  // --- Cooking time ---
  static const String cookingUnder10Min = 'under_10_min';
  static const String cookingTenTo30Min = 'ten_to_30_min';
  static const String cookingThirtyTo60Min = 'thirty_to_60_min';
  static const String cookingOver60Min = 'over_60_min';
  static const String cookingNotParticular = 'not_particular';

  static const List<String> cookingKeys = [
    cookingUnder10Min,
    cookingTenTo30Min,
    cookingThirtyTo60Min,
    cookingOver60Min,
    cookingNotParticular,
  ];

  // --- Sentinels ---
  static const String noCuisineSelected = 'no_cuisine_selected';
  static const String noCookingPreference = 'no_cooking_preference';
  static const String noDietRestrictions = 'no_diet_restrictions';

  // --- Allergens ---
  static const String allergenMilkDairy = 'milk_dairy';
  static const String allergenEggs = 'eggs';
  static const String allergenFish = 'fish';
  static const String allergenShellfish = 'shellfish';
  static const String allergenPeanuts = 'peanuts';
  static const String allergenTreeNuts = 'tree_nuts';
  static const String allergenWheatGluten = 'wheat_gluten';
  static const String allergenSoy = 'soy';
  static const String allergenSesame = 'sesame';
  static const String allergenMustard = 'mustard';
  static const String allergenSulfites = 'sulfites';

  static const List<String> allergenKeys = [
    allergenMilkDairy,
    allergenEggs,
    allergenFish,
    allergenShellfish,
    allergenPeanuts,
    allergenTreeNuts,
    allergenWheatGluten,
    allergenSoy,
    allergenSesame,
    allergenMustard,
    allergenSulfites,
  ];

  static const Map<String, String> _legacyMoodEnglish = {
    'Happy/Excited': moodHappyExcited,
    'Sad/Tired': moodSadTired,
    'Not Hungry': moodNotHungry,
    'Neutral': moodNeutral,
    'I am feeling lucky! (Suggest any recipe)': moodFeelingLucky,
    'Angry': moodAngry,
    'Confused': moodConfused,
    'lucky': moodFeelingLucky,
  };

  static const Map<String, String> _legacyDietEnglish = {
    'Vegetarian': dietVegetarian,
    'Vegan': dietVegan,
    'Pescitarian': dietPescitarian,
    'Non Vegetarian Without Red Meat': dietNonVegetarianWithoutRedMeat,
    'Non Vegetarian with no restrictions': dietNonVegetarianWithRedMeat,
    'No Nuts in my food.': dietNutFree,
    'Paleo': dietPaleo,
    'Keto': dietKeto,
    'Gluten Free': dietGlutenFree,
    'No Restrictions': dietNoRestrictions,
    'No Diet Restrictions': noDietRestrictions,
    'Halal': dietHalal,
    'Kosher': dietKosher,
  };

  static const Map<String, String> _legacyCuisineEnglish = {
    'Indian': cuisineIndian,
    'Mexican': cuisineMexican,
    'Chinese': cuisineChinese,
    'Thai': cuisineThai,
    'Korean': cuisineKorean,
    'Italian': cuisineItalian,
    'American': cuisineAmerican,
    'Surprise Me with anything!': cuisineSurpriseMe,
    'Popular': cuisinePopular,
    'No Cuisine Selected': noCuisineSelected,
  };

  static const Map<String, String> _legacyCookingEnglish = {
    '< 10 Minutes': cookingUnder10Min,
    '10 – 30 Minutes': cookingTenTo30Min,
    '30 – 60 Minutes': cookingThirtyTo60Min,
    '> 60 Minutes': cookingOver60Min,
    'Not Particular': cookingNotParticular,
    'No Cooking Preferences': noCookingPreference,
  };

  static const Map<String, String> _legacyAllergenEnglish = {
    'Milk / dairy': allergenMilkDairy,
    'Eggs': allergenEggs,
    'Fish': allergenFish,
    'Shellfish': allergenShellfish,
    'Peanuts': allergenPeanuts,
    'Tree nuts': allergenTreeNuts,
    'Wheat / gluten': allergenWheatGluten,
    'Soy': allergenSoy,
    'Sesame': allergenSesame,
    'Mustard': allergenMustard,
    'Sulfites': allergenSulfites,
  };

  static const Map<String, String> _moodApiEnglish = {
    moodHappyExcited: 'Happy/Excited',
    moodSadTired: 'Sad/Tired',
    moodNotHungry: 'Not Hungry',
    moodNeutral: 'Neutral',
    moodFeelingLucky: 'I am feeling lucky! (Suggest any recipe)',
    moodAngry: 'Angry',
    moodConfused: 'Confused',
  };

  static const Map<String, String> _dietApiEnglish = {
    dietVegetarian: 'Vegetarian',
    dietVegan: 'Vegan',
    dietPescitarian: 'Pescitarian',
    dietNonVegetarianWithoutRedMeat: 'Non Vegetarian Without Red Meat',
    dietNonVegetarianWithRedMeat: 'Non Vegetarian with no restrictions',
    dietNutFree: 'No Nuts in my food.',
    dietPaleo: 'Paleo',
    dietKeto: 'Keto',
    dietGlutenFree: 'Gluten Free',
    dietNoRestrictions: 'No Restrictions',
    noDietRestrictions: 'No Diet Restrictions',
    dietHalal: 'Halal',
    dietKosher: 'Kosher',
  };

  static const Map<String, String> _cuisineApiEnglish = {
    cuisineIndian: 'Indian',
    cuisineMexican: 'Mexican',
    cuisineChinese: 'Chinese',
    cuisineThai: 'Thai',
    cuisineKorean: 'Korean',
    cuisineItalian: 'Italian',
    cuisineAmerican: 'American',
    cuisineSurpriseMe: 'Surprise Me with anything!',
    cuisinePopular: 'Popular',
    noCuisineSelected: 'No Cuisine Selected',
  };

  static const Map<String, String> _cookingApiEnglish = {
    cookingUnder10Min: '< 10 Minutes',
    cookingTenTo30Min: '10 – 30 Minutes',
    cookingThirtyTo60Min: '30 – 60 Minutes',
    cookingOver60Min: '> 60 Minutes',
    cookingNotParticular: 'Not Particular',
    noCookingPreference: 'No Cooking Preferences',
  };

  static const Map<String, String> _allergenApiEnglish = {
    allergenMilkDairy: 'Milk / dairy',
    allergenEggs: 'Eggs',
    allergenFish: 'Fish',
    allergenShellfish: 'Shellfish',
    allergenPeanuts: 'Peanuts',
    allergenTreeNuts: 'Tree nuts',
    allergenWheatGluten: 'Wheat / gluten',
    allergenSoy: 'Soy',
    allergenSesame: 'Sesame',
    allergenMustard: 'Mustard',
    allergenSulfites: 'Sulfites',
  };

  static String normalizeMoodKey(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return moodFeelingLucky;
    if (moodKeys.contains(t)) return t;
    return _legacyMoodEnglish[t] ?? moodFeelingLucky;
  }

  static String normalizeDietKey(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return noDietRestrictions;
    if (dietKeys.contains(t) || t == dietHalal || t == dietKosher) return t;
    if (t == noDietRestrictions) return t;
    return _legacyDietEnglish[t] ?? noDietRestrictions;
  }

  static String normalizeCuisineKey(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return noCuisineSelected;
    if (cuisineKeys.contains(t) || t == cuisinePopular) return t;
    if (t == noCuisineSelected) return t;
    return _legacyCuisineEnglish[t] ?? noCuisineSelected;
  }

  static String normalizeCookingKey(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return noCookingPreference;
    if (cookingKeys.contains(t)) return t;
    if (t == noCookingPreference) return t;
    return _legacyCookingEnglish[t] ?? noCookingPreference;
  }

  static String normalizeAllergenKey(String? raw) {
    final t = raw?.trim() ?? '';
    if (t.isEmpty) return t;
    if (allergenKeys.contains(t)) return t;
    return _legacyAllergenEnglish[t] ?? t;
  }

  static List<String> normalizeAllergenKeys(List<String> raw) =>
      raw.map(normalizeAllergenKey).where((e) => e.isNotEmpty).toList();

  static List<String> normalizeDietProfileKeys(List<String> raw) =>
      raw.map(normalizeDietKey).where((k) => k != dietNoRestrictions).toList();

  static List<String> normalizeCuisineKeys(List<String> raw) =>
      raw.map(normalizeCuisineKey).toList();

  static bool isFeelingLucky(String? raw) =>
      normalizeMoodKey(raw) == moodFeelingLucky;

  static bool isNoRestrictionsDiet(String? raw) {
    final k = normalizeDietKey(raw);
    return k == dietNoRestrictions || k == noDietRestrictions;
  }

  static bool isSurpriseCuisine(String? raw) =>
      normalizeCuisineKey(raw) == cuisineSurpriseMe;

  static bool isNotParticularCooking(String? raw) {
    final k = normalizeCookingKey(raw);
    return k == cookingNotParticular || k == noCookingPreference;
  }

  static bool isNoCuisineSelected(String? raw) =>
      normalizeCuisineKey(raw) == noCuisineSelected;

  static String moodToApiEnglish(String? raw) =>
      _moodApiEnglish[normalizeMoodKey(raw)] ?? _moodApiEnglish[moodFeelingLucky]!;

  static String dietToApiEnglish(String? raw) =>
      _dietApiEnglish[normalizeDietKey(raw)] ??
      _dietApiEnglish[noDietRestrictions]!;

  static String cuisineToApiEnglish(String? raw) =>
      _cuisineApiEnglish[normalizeCuisineKey(raw)] ??
      _cuisineApiEnglish[noCuisineSelected]!;

  static String cookingToApiEnglish(String? raw) =>
      _cookingApiEnglish[normalizeCookingKey(raw)] ??
      _cookingApiEnglish[noCookingPreference]!;

  static String allergenToApiEnglish(String? raw) {
    final key = normalizeAllergenKey(raw);
    return _allergenApiEnglish[key] ?? raw ?? '';
  }

  static String cuisinesToApiEnglishJoined(List<String> keys) {
    final labels = keys
        .map(normalizeCuisineKey)
        .where((k) => k.isNotEmpty && k != cuisineSurpriseMe && k != noCuisineSelected)
        .map((k) => _cuisineApiEnglish[k] ?? k)
        .toList();
    if (labels.isEmpty) return _cuisineApiEnglish[noCuisineSelected]!;
    return labels.join(', ');
  }

  static String moodLabel(String key, AppLocalizations l10n) {
    switch (normalizeMoodKey(key)) {
      case moodHappyExcited:
        return l10n.moodHappyExcited;
      case moodSadTired:
        return l10n.moodSadTired;
      case moodNotHungry:
        return l10n.moodNotHungry;
      case moodNeutral:
        return l10n.moodNeutral;
      case moodFeelingLucky:
        return l10n.moodFeelingLucky;
      case moodAngry:
        return l10n.moodAngry;
      case moodConfused:
        return l10n.moodConfused;
      default:
        return key;
    }
  }

  static String dietLabel(String key, AppLocalizations l10n) {
    switch (normalizeDietKey(key)) {
      case dietVegetarian:
        return l10n.dietVegetarian;
      case dietVegan:
        return l10n.dietVegan;
      case dietPescitarian:
        return l10n.dietPescitarian;
      case dietNonVegetarianWithoutRedMeat:
        return l10n.dietNonVegetarianWithoutRedMeat;
      case dietNonVegetarianWithRedMeat:
        return l10n.dietNonVegetarianWithRedMeat;
      case dietNutFree:
        return l10n.dietNutFree;
      case dietPaleo:
        return l10n.dietPaleo;
      case dietKeto:
        return l10n.dietKeto;
      case dietGlutenFree:
        return l10n.dietGlutenFree;
      case dietNoRestrictions:
        return l10n.dietNoRestrictions;
      case dietHalal:
        return l10n.dietHalal;
      case dietKosher:
        return l10n.dietKosher;
      default:
        return key;
    }
  }

  static String cuisineLabel(String key, AppLocalizations l10n) {
    switch (normalizeCuisineKey(key)) {
      case cuisineIndian:
        return l10n.cuisineIndian;
      case cuisineMexican:
        return l10n.cuisineMexican;
      case cuisineChinese:
        return l10n.cuisineChinese;
      case cuisineThai:
        return l10n.cuisineThai;
      case cuisineKorean:
        return l10n.cuisineKorean;
      case cuisineItalian:
        return l10n.cuisineItalian;
      case cuisineAmerican:
        return l10n.cuisineAmerican;
      case cuisineSurpriseMe:
        return l10n.cuisineSurpriseMe;
      case cuisinePopular:
        return l10n.cuisinePopular;
      default:
        return key;
    }
  }

  static String cookingLabel(String key, AppLocalizations l10n) {
    switch (normalizeCookingKey(key)) {
      case cookingUnder10Min:
        return l10n.cookingUnder10Min;
      case cookingTenTo30Min:
        return l10n.cookingTenTo30Min;
      case cookingThirtyTo60Min:
        return l10n.cookingThirtyTo60Min;
      case cookingOver60Min:
        return l10n.cookingOver60Min;
      case cookingNotParticular:
        return l10n.cookingNotParticular;
      default:
        return key;
    }
  }

  static String allergenLabel(String key, AppLocalizations l10n) {
    switch (normalizeAllergenKey(key)) {
      case allergenMilkDairy:
        return l10n.allergenMilkDairy;
      case allergenEggs:
        return l10n.allergenEggs;
      case allergenFish:
        return l10n.allergenFish;
      case allergenShellfish:
        return l10n.allergenShellfish;
      case allergenPeanuts:
        return l10n.allergenPeanuts;
      case allergenTreeNuts:
        return l10n.allergenTreeNuts;
      case allergenWheatGluten:
        return l10n.allergenWheatGluten;
      case allergenSoy:
        return l10n.allergenSoy;
      case allergenSesame:
        return l10n.allergenSesame;
      case allergenMustard:
        return l10n.allergenMustard;
      case allergenSulfites:
        return l10n.allergenSulfites;
      default:
        return key;
    }
  }
}
