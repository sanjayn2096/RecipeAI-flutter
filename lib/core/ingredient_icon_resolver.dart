import 'grocery_ingredient_display.dart';

/// Resolves ingredient labels to raster assets with manual canonical + synonym maps.
abstract class IngredientIconResolver {
  IngredientIconResolver._();

  static const String _assetPrefix = 'assets/ingredient_icons/';
  static const String fallbackAsset = '${_assetPrefix}pantry.png';

  /// Canonical keys use space-separated wording matching [_normalizeText] output.
  static const Map<String, String> canonicalIngredientToAsset = {
    'avocado': '${_assetPrefix}avocado.png',
    'black beans': '${_assetPrefix}black_beans.png',
    'mushroom': '${_assetPrefix}mushroom.png',
    'banana': '${_assetPrefix}banana.png',
    'basil': '${_assetPrefix}basil.png',
    'egg': '${_assetPrefix}egg.png',
    'cooking oil': '${_assetPrefix}cooking_oil.png',
    'black pepper': '${_assetPrefix}black_pepper.png',
    'beetroot': '${_assetPrefix}beetroot.png',
    'green chili': '${_assetPrefix}green_chilli.png',
    'coconut milk': '${_assetPrefix}coconut_milk.png',
    'cheese': '${_assetPrefix}cheese.png',
    'bread': '${_assetPrefix}bread.png',
    'garlic': '${_assetPrefix}garlic.png',
    'butter': '${_assetPrefix}butter.png',
    'corn': '${_assetPrefix}corn.png',
    'fish': '${_assetPrefix}fish.png',
    'chicken': '${_assetPrefix}chicken.png',
    'ginger': '${_assetPrefix}ginger.png',
    'red chili': '${_assetPrefix}red_chilli.png',
    'cayenne pepper': '${_assetPrefix}cayenne_pepper.png',
    'salt': '${_assetPrefix}salt.png',
    'mint': '${_assetPrefix}mint.png',
    'berries': '${_assetPrefix}berries.png',
    'tofu': '${_assetPrefix}tofu.png',
    'milk': '${_assetPrefix}milk.png',
    'tortillas': '${_assetPrefix}tortillas.png',
    'eggs': '${_assetPrefix}eggs.png',
    'lime': '${_assetPrefix}lime.png',
    'spring onion': '${_assetPrefix}spring_onion.png',
    'yogurt': '${_assetPrefix}yogurt.png',
    'onion': '${_assetPrefix}onion.png',
    'turmeric': '${_assetPrefix}turmeric.png',
    'parsley': '${_assetPrefix}parsley.png',
    'apple': '${_assetPrefix}apple.png',
    'red beans': '${_assetPrefix}red_beans.png',
    'matcha': '${_assetPrefix}matcha.png',
    'pasta': '${_assetPrefix}pasta.png',
    'pineapple': '${_assetPrefix}pineapple.png',
    'pork': '${_assetPrefix}pork.png',
    'yellow bell pepper': '${_assetPrefix}yellow_bell_pepper.png',
    'quinoa': '${_assetPrefix}quinoa.png',
    'red bell pepper': '${_assetPrefix}red_bell_pepper.png',
    'chop': '${_assetPrefix}chop.png',
    'paneer': '${_assetPrefix}paneer.png',
    'green bell pepper': '${_assetPrefix}green_bell_pepper.png',
    'soup': '${_assetPrefix}soup.png',
    'beef': '${_assetPrefix}beef.png',
    'honey': '${_assetPrefix}honey.png',
    'lemon': '${_assetPrefix}lemon.png',
  };

  static const Map<String, String> synonymToCanonical = {
    // Plurals / direct variants
    'avocados': 'avocado',
    'mushrooms': 'mushroom',
    'bananas': 'banana',
    'apples': 'apple',
    'pineapples': 'pineapple',
    'onions': 'onion',
    'eggs': 'eggs',
    'egg': 'egg',

    // Beans and legumes
    'black bean': 'black beans',
    'canned black beans': 'black beans',
    'pinto beans': 'red beans',
    'kidney beans': 'red beans',
    'beans': 'red beans',
    'bean': 'red beans',
    'toor dal': 'red beans',
    'moong dal': 'red beans',
    'chana dal': 'red beans',
    'masoor dal': 'red beans',
    'urad dal': 'red beans',
    'lentil': 'red beans',
    'lentils': 'red beans',
    'chickpea': 'red beans',
    'chick peas': 'red beans',
    'garbanzo': 'red beans',

    // Eggs
    'boiled egg': 'egg',
    'boiled eggs': 'eggs',

    // Oils
    'olive oil': 'cooking oil',
    'extra virgin olive oil': 'cooking oil',
    'evoo': 'cooking oil',
    'mustard oil': 'cooking oil',
    'sesame oil': 'cooking oil',
    'vegetable oil': 'cooking oil',
    'canola oil': 'cooking oil',
    'rapeseed oil': 'cooking oil',
    'chili oil': 'cooking oil',
    'sunflower oil': 'cooking oil',

    // Pepper and chili
    'peppercorn': 'black pepper',
    'black peppercorn': 'black pepper',
    'green chilli': 'green chili',
    'green chile': 'green chili',
    'green chili pepper': 'green chili',
    'fresh green chili': 'green chili',
    'jalapeno': 'green chili',
    'serrano': 'green chili',
    'red chilli': 'red chili',
    'chili pepper': 'red chili',
    'chilli': 'red chili',
    'chile': 'red chili',
    'chili powder': 'red chili',
    'chilli powder': 'red chili',
    'crushed red pepper': 'red chili',

    // Ground cayenne artwork (distinct from generic red chili PNG)
    'cayenne': 'cayenne pepper',
    'cayenne powder': 'cayenne pepper',
    'ground cayenne': 'cayenne pepper',
    'dried cayenne': 'cayenne pepper',

    // Dairy / protein
    'curd': 'yogurt',
    'plain yogurt': 'yogurt',
    'greek yogurt': 'yogurt',
    'yoghurt': 'yogurt',
    'cheddar': 'cheese',
    'mozzarella': 'cheese',
    'parmesan': 'cheese',
    'paneer': 'paneer',

    'salmon' : 'fish',
    'cod': 'fish',
    'basa' : 'fish',
    'trout' : 'fish',
    'chicken breast': 'chicken',
    'chicken thigh': 'chicken',
    'chicken thighs': 'chicken',
    'pork chop': 'chop',
    'pork chops': 'chop',
    'ham': 'pork',
    'bacon': 'pork',
    'ground beef': 'beef',
    'minced beef': 'beef',
    'beef mince': 'beef',
    'steak': 'beef',
    'sirloin': 'beef',
    'brisket': 'beef',

    // Coconut / pantry staples
    'coconut': 'coconut milk',
    'sea salt': 'salt',
    'kosher salt': 'salt',
    'table salt': 'salt',
    'haldi': 'turmeric',
    'turmeric powder': 'turmeric',
    'honey jar': 'honey',
    'raw honey': 'honey',
    'lemon juice': 'lemon',
    'lemon zest': 'lemon',
    'lemons': 'lemon',
    'broth': 'soup',
    'stock': 'soup',
    'vegetable broth': 'soup',
    'chicken broth': 'soup',
    'vegetable stock': 'soup',
    'chicken stock': 'soup',

    /// Berry cluster PNG (saved as acai-berries; reused for mixed berry wording).
    'blueberries': 'berries',
    'blueberry': 'berries',
    'blackberries': 'berries',
    'blackberry': 'berries',
    'strawberries': 'berries',
    'strawberry': 'berries',
    'acai': 'berries',
    'cranberries': 'berries',
    'cranberry': 'berries',
    'raspberries': 'berries',
    'raspberry': 'berries',

    // Bread / grains / pasta
    'toast': 'bread',
    'slice of bread': 'bread',
    'bread slice': 'bread',
    'noodles': 'pasta',
    'rice noodles': 'pasta',

    // Produce and herbs
    'beets': 'beetroot',
    'beet': 'beetroot',
    'button mushrooms': 'mushroom',
    'shiitake': 'mushroom',
    'cremini': 'mushroom',
    'baby bella': 'mushroom',
    'portabella': 'mushroom',
    'porcini': 'mushroom',
    'corn kernels': 'corn',
    'sweet corn': 'corn',
    'bell pepper': 'red bell pepper',
    'bell peppers': 'red bell pepper',
    'capsicum': 'red bell pepper',
    'red pepper': 'red bell pepper',
    'red peppers': 'red bell pepper',
    'yellow pepper': 'yellow bell pepper',
    'yellow peppers': 'yellow bell pepper',
    'green pepper': 'green bell pepper',
    'green peppers': 'green bell pepper',
    'shallot': 'onion',
    'shallots': 'onion',
    'spring onions': 'spring onion',
    'scallion': 'spring onion',
    'scallions': 'spring onion',
    'coriander': 'parsley',
    'cilantro': 'parsley',
    'coriander leaves': 'parsley',
    'dhaniya': 'parsley',
    'dhaniya powder': 'parsley',
    'thai basil': 'basil',
    'lime juice': 'lime',
    'garlic cloves': 'garlic',
    'garlic clove': 'garlic',

    // Matcha
    'matcha powder': 'matcha',
    'green tea powder': 'matcha',
  };

  static final List<String> _phraseCandidates = [
    ...canonicalIngredientToAsset.keys,
    ...synonymToCanonical.keys,
  ]..sort((a, b) => b.length.compareTo(a.length));

  static String resolveAssetFor(String rawIngredientName) {
    final canonical = resolveCanonicalFor(rawIngredientName);
    if (canonical == null) return fallbackAsset;
    return canonicalIngredientToAsset[canonical] ?? fallbackAsset;
  }

  static String? resolveCanonicalFor(String rawIngredientName) {
    final candidates = <String>{
      _normalizeText(rawIngredientName),
      _normalizeText(
        GroceryIngredientDisplay.baseIngredientKey(rawIngredientName),
      ),
    }..removeWhere((e) => e.isEmpty);

    for (final candidate in candidates) {
      final exactCanonical = _exactCanonical(candidate);
      if (exactCanonical != null) return exactCanonical;
    }

    for (final candidate in candidates) {
      for (final phrase in _phraseCandidates) {
        if (phrase.contains(' ') && candidate.contains(phrase)) {
          return _exactCanonical(phrase);
        }
      }
    }

    for (final candidate in candidates) {
      final words = candidate.split(' ');
      for (final word in words) {
        final exactCanonical = _exactCanonical(word);
        if (exactCanonical != null) return exactCanonical;
      }
    }

    return null;
  }

  /// True when [rawIngredientName] resolves to an ingredient PNG (not generic pantry).
  static bool hasIngredientMatch(String rawIngredientName) {
    final canonical = resolveCanonicalFor(rawIngredientName);
    if (canonical == null) return false;
    return canonicalIngredientToAsset.containsKey(canonical);
  }

  static String? _exactCanonical(String normalizedName) {
    if (normalizedName.isEmpty) return null;
    if (canonicalIngredientToAsset.containsKey(normalizedName)) {
      return normalizedName;
    }
    final viaSynonym = synonymToCanonical[normalizedName];
    if (viaSynonym == null) return null;
    if (canonicalIngredientToAsset.containsKey(viaSynonym)) {
      return viaSynonym;
    }
    return _exactCanonical(viaSynonym);
  }

  static String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
