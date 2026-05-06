import 'grocery_ingredient_display.dart';

/// Resolves ingredient names to SVG assets with manual canonical + synonym maps.
abstract class IngredientIconResolver {
  IngredientIconResolver._();

  static const String _assetPrefix = 'assets/ingredient_icons/';
  static const String fallbackAsset = '${_assetPrefix}ingredient_default.svg';

  static const Map<String, String> canonicalIngredientToAsset = {
    'apple': '${_assetPrefix}apple.svg',
    'apricot': '${_assetPrefix}apricot.svg',
    'avocado': '${_assetPrefix}avocado.svg',
    'banana': '${_assetPrefix}banana.svg',
    'blackberry': '${_assetPrefix}blackberry.svg',
    'blueberry': '${_assetPrefix}blueberry.svg',
    'cherry': '${_assetPrefix}cherry.svg',
    'coconut': '${_assetPrefix}coconut.svg',
    'cranberry': '${_assetPrefix}cranberry.svg',
    'date': '${_assetPrefix}date.svg',
    'fig': '${_assetPrefix}fig.svg',
    'grape': '${_assetPrefix}grape.svg',
    'grapefruit': '${_assetPrefix}grapefruit.svg',
    'guava': '${_assetPrefix}guava.svg',
    'kiwi': '${_assetPrefix}kiwi.svg',
    'lemon': '${_assetPrefix}lemon.svg',
    'lime': '${_assetPrefix}lime.svg',
    'mango': '${_assetPrefix}mango.svg',
    'melon': '${_assetPrefix}melon.svg',
    'orange': '${_assetPrefix}orange.svg',
    'papaya': '${_assetPrefix}papaya.svg',
    'peach': '${_assetPrefix}peach.svg',
    'pear': '${_assetPrefix}pear.svg',
    'pineapple': '${_assetPrefix}pineapple.svg',
    'plum': '${_assetPrefix}plum.svg',
    'pomegranate': '${_assetPrefix}pomegranate.svg',
    'raspberry': '${_assetPrefix}raspberry.svg',
    'strawberry': '${_assetPrefix}strawberry.svg',
    'watermelon': '${_assetPrefix}watermelon.svg',
    'artichoke': '${_assetPrefix}artichoke.svg',
    'arugula': '${_assetPrefix}arugula.svg',
    'asparagus': '${_assetPrefix}asparagus.svg',
    'beetroot': '${_assetPrefix}beetroot.svg',
    'bell pepper': '${_assetPrefix}bell_pepper.svg',
    'bok choy': '${_assetPrefix}bok_choy.svg',
    'broccoli': '${_assetPrefix}broccoli.svg',
    'brussels sprouts': '${_assetPrefix}brussels_sprouts.svg',
    'cabbage': '${_assetPrefix}cabbage.svg',
    'carrot': '${_assetPrefix}carrot.svg',
    'cauliflower': '${_assetPrefix}cauliflower.svg',
    'celery': '${_assetPrefix}celery.svg',
    'chili pepper': '${_assetPrefix}chili_pepper.svg',
    'corn': '${_assetPrefix}corn.svg',
    'cucumber': '${_assetPrefix}cucumber.svg',
    'eggplant': '${_assetPrefix}eggplant.svg',
    'fennel': '${_assetPrefix}fennel.svg',
    'garlic': '${_assetPrefix}garlic.svg',
    'ginger': '${_assetPrefix}ginger.svg',
    'green bean': '${_assetPrefix}green_bean.svg',
    'green onion': '${_assetPrefix}green_onion.svg',
    'jalapeno': '${_assetPrefix}jalapeno.svg',
    'kale': '${_assetPrefix}kale.svg',
    'leek': '${_assetPrefix}leek.svg',
    'lettuce': '${_assetPrefix}lettuce.svg',
    'mushroom': '${_assetPrefix}mushroom.svg',
    'okra': '${_assetPrefix}okra.svg',
    'olive': '${_assetPrefix}olive.svg',
    'onion': '${_assetPrefix}onion.svg',
    'parsley': '${_assetPrefix}parsley.svg',
    'pea': '${_assetPrefix}pea.svg',
    'potato': '${_assetPrefix}potato.svg',
    'pumpkin': '${_assetPrefix}pumpkin.svg',
    'radish': '${_assetPrefix}radish.svg',
    'spinach': '${_assetPrefix}spinach.svg',
    'sweet potato': '${_assetPrefix}sweet_potato.svg',
    'tomato': '${_assetPrefix}tomato.svg',
    'turnip': '${_assetPrefix}turnip.svg',
    'zucchini': '${_assetPrefix}zucchini.svg',
    'almond': '${_assetPrefix}almond.svg',
    'cashew': '${_assetPrefix}cashew.svg',
    'chia seed': '${_assetPrefix}chia_seed.svg',
    'flax seed': '${_assetPrefix}flax_seed.svg',
    'hazelnut': '${_assetPrefix}hazelnut.svg',
    'peanut': '${_assetPrefix}peanut.svg',
    'pistachio': '${_assetPrefix}pistachio.svg',
    'sesame seed': '${_assetPrefix}sesame_seed.svg',
    'sunflower seed': '${_assetPrefix}sunflower_seed.svg',
    'walnut': '${_assetPrefix}walnut.svg',
    'basil': '${_assetPrefix}basil.svg',
    'bay leaf': '${_assetPrefix}bay_leaf.svg',
    'black pepper': '${_assetPrefix}black_pepper.svg',
    'cardamom': '${_assetPrefix}cardamom.svg',
    'cayenne': '${_assetPrefix}cayenne.svg',
    'cinnamon': '${_assetPrefix}cinnamon.svg',
    'clove': '${_assetPrefix}clove.svg',
    'coriander': '${_assetPrefix}coriander.svg',
    'cumin': '${_assetPrefix}cumin.svg',
    'curry leaf': '${_assetPrefix}curry_leaf.svg',
    'dill': '${_assetPrefix}dill.svg',
    'mint': '${_assetPrefix}mint.svg',
    'nutmeg': '${_assetPrefix}nutmeg.svg',
    'oregano': '${_assetPrefix}oregano.svg',
    'paprika': '${_assetPrefix}paprika.svg',
    'rosemary': '${_assetPrefix}rosemary.svg',
    'saffron': '${_assetPrefix}saffron.svg',
    'sage': '${_assetPrefix}sage.svg',
    'star anise': '${_assetPrefix}star_anise.svg',
    'thyme': '${_assetPrefix}thyme.svg',
    'turmeric': '${_assetPrefix}turmeric.svg',
    'vanilla': '${_assetPrefix}vanilla.svg',
    'beef': '${_assetPrefix}beef.svg',
    'chicken': '${_assetPrefix}chicken.svg',
    'duck': '${_assetPrefix}duck.svg',
    'goat': '${_assetPrefix}goat.svg',
    'lamb': '${_assetPrefix}lamb.svg',
    'pork': '${_assetPrefix}pork.svg',
    'turkey': '${_assetPrefix}turkey.svg',
    'bacon': '${_assetPrefix}bacon.svg',
    'ham': '${_assetPrefix}ham.svg',
    'sausage': '${_assetPrefix}sausage.svg',
    'anchovy': '${_assetPrefix}anchovy.svg',
    'cod': '${_assetPrefix}cod.svg',
    'crab': '${_assetPrefix}crab.svg',
    'fish': '${_assetPrefix}fish.svg',
    'lobster': '${_assetPrefix}lobster.svg',
    'mackerel': '${_assetPrefix}mackerel.svg',
    'salmon': '${_assetPrefix}salmon.svg',
    'sardine': '${_assetPrefix}sardine.svg',
    'shrimp': '${_assetPrefix}shrimp.svg',
    'tilapia': '${_assetPrefix}tilapia.svg',
    'tuna': '${_assetPrefix}tuna.svg',
    'egg': '${_assetPrefix}egg.svg',
    'butter': '${_assetPrefix}butter.svg',
    'cheese': '${_assetPrefix}cheese.svg',
    'cream': '${_assetPrefix}cream.svg',
    'ghee': '${_assetPrefix}ghee.svg',
    'milk': '${_assetPrefix}milk.svg',
    'yogurt': '${_assetPrefix}yogurt.svg',
    'rice': '${_assetPrefix}rice.svg',
    'quinoa': '${_assetPrefix}quinoa.svg',
    'semolina': '${_assetPrefix}semolina.svg',
    'oats': '${_assetPrefix}oats.svg',
    'barley': '${_assetPrefix}barley.svg',
    'lentil': '${_assetPrefix}lentil.svg',
    'chickpea': '${_assetPrefix}chickpea.svg',
    'bread': '${_assetPrefix}bread.svg',
    'pasta': '${_assetPrefix}pasta.svg',
    'noodles': '${_assetPrefix}noodles.svg',
    'flour': '${_assetPrefix}flour.svg',
    'corn flour': '${_assetPrefix}corn_flour.svg',
    'chickpea flour': '${_assetPrefix}chickpea_flour.svg',
    'sugar': '${_assetPrefix}sugar.svg',
    'brown sugar': '${_assetPrefix}brown_sugar.svg',
    'honey': '${_assetPrefix}honey.svg',
    'maple syrup': '${_assetPrefix}maple_syrup.svg',
    'olive oil': '${_assetPrefix}olive_oil.svg',
    'canola oil': '${_assetPrefix}canola_oil.svg',
    'sesame oil': '${_assetPrefix}sesame_oil.svg',
    'coconut oil': '${_assetPrefix}coconut_oil.svg',
    'vinegar': '${_assetPrefix}vinegar.svg',
    'soy sauce': '${_assetPrefix}soy_sauce.svg',
    'fish sauce': '${_assetPrefix}fish_sauce.svg',
    'hot sauce': '${_assetPrefix}hot_sauce.svg',
    'mustard': '${_assetPrefix}mustard.svg',
    'ketchup': '${_assetPrefix}ketchup.svg',
    'mayonnaise': '${_assetPrefix}mayonnaise.svg',
    'salt': '${_assetPrefix}salt.svg',
    'water': '${_assetPrefix}water.svg',
  };

  static const Map<String, String> synonymToCanonical = {
    'capsicum': 'bell pepper',
    'pepper': 'bell pepper',
    'red pepper': 'bell pepper',
    'green pepper': 'bell pepper',
    'yellow pepper': 'bell pepper',
    'scallion': 'green onion',
    'spring onion': 'green onion',
    'green onions': 'green onion',
    'scallions': 'green onion',
    'chilli': 'chili pepper',
    'chile': 'chili pepper',
    'red chili': 'chili pepper',
    'green chili': 'chili pepper',
    'coriander leaves': 'coriander',
    'cilantro': 'coriander',
    'dhania': 'coriander',
    'aubergine': 'eggplant',
    'courgette': 'zucchini',
    'garbanzo bean': 'chickpea',
    'atta': 'flour',
    'maida': 'flour',
    'all purpose flour': 'flour',
    'plain flour': 'flour',
    'powdered sugar': 'sugar',
    'icing sugar': 'sugar',
    'confectioners sugar': 'sugar',
    'caster sugar': 'sugar',
    'demerara': 'brown sugar',
    'scotch bonnet': 'chili pepper',
    'serrano': 'chili pepper',
    'bird eye chili': 'chili pepper',
    'green beans': 'green bean',
    'peas': 'pea',
    'potatoes': 'potato',
    'onions': 'onion',
    'tomatoes': 'tomato',
    'carrots': 'carrot',
    'mushrooms': 'mushroom',
    'eggs': 'egg',
    'prawns': 'shrimp',
    'prawn': 'shrimp',
    'chicken breast': 'chicken',
    'chicken thighs': 'chicken',
    'chicken thigh': 'chicken',
    'ground beef': 'beef',
    'minced beef': 'beef',
    'beef mince': 'beef',
    'ground pork': 'pork',
    'minced pork': 'pork',
    'extra virgin olive oil': 'olive oil',
    'evoo': 'olive oil',
    'vegetable oil': 'canola oil',
    'rapeseed oil': 'canola oil',
    'toor dal': 'lentil',
    'masoor dal': 'lentil',
    'moong dal': 'lentil',
    'urad dal': 'lentil',
    'lentils': 'lentil',
    'basmati rice': 'rice',
    'jasmine rice': 'rice',
    'apple cider vinegar': 'vinegar',
    'white vinegar': 'vinegar',
    'red wine vinegar': 'vinegar',
    'sea salt': 'salt',
    'kosher salt': 'salt',
    'table salt': 'salt',
    'black peppercorn': 'black pepper',
    'peppercorn': 'black pepper',
    'garam masala': 'cumin',
    'curry powder': 'turmeric',
    'plain yogurt': 'yogurt',
    'greek yogurt': 'yogurt',
    'yoghurt': 'yogurt',
    'heavy cream': 'cream',
    'double cream': 'cream',
    'whipping cream': 'cream',
    'cheddar': 'cheese',
    'mozzarella': 'cheese',
    'parmesan': 'cheese',
    'shallot': 'onion',
    'shallots': 'onion',
    'rocket': 'arugula',
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
      _normalizeText(GroceryIngredientDisplay.baseIngredientKey(rawIngredientName)),
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

  static String? _exactCanonical(String normalizedName) {
    if (normalizedName.isEmpty) return null;
    if (canonicalIngredientToAsset.containsKey(normalizedName)) {
      return normalizedName;
    }
    return synonymToCanonical[normalizedName];
  }

  static String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
