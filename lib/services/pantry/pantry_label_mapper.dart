/// Maps Apple Vision / ML Kit classifier identifiers to grocery display names.
abstract class PantryLabelMapper {
  PantryLabelMapper._();

  static const double minConfidence = 0.35;

  /// Non-food identifiers to ignore from classifiers.
  static const Set<String> _blocklist = {
    'outdoor',
    'indoor',
    'room',
    'furniture',
    'person',
    'people',
    'clothing',
    'vehicle',
    'car',
    'building',
    'sky',
    'wall',
    'floor',
    'table',
    'chair',
    'computer',
    'phone',
    'book',
    'paper',
    'text',
    'sign',
    'logo',
    'packaging',
    'container',
    'bottle',
    'jar',
    'can',
    'box',
    'bag',
    'refrigerator',
    'kitchen',
    'shelf',
    'countertop',
    'structure',
    'liquid',
    'water',
    'plant',
    'foliage',
    'painting',
    'screenshot',
    'document',
  };

  /// Vision identifier → grocery display name.
  static const Map<String, String> _foodLabels = {
    'apple': 'Apple',
    'apricot': 'Apricot',
    'artichoke': 'Artichoke',
    'asparagus': 'Asparagus',
    'avocado': 'Avocado',
    'bacon': 'Bacon',
    'bagel': 'Bagel',
    'baguette': 'Bread',
    'baked_goods': 'Baked Goods',
    'banana': 'Banana',
    'bean': 'Beans',
    'beef': 'Beef',
    'beer': 'Beer',
    'beet': 'Beets',
    'bell_pepper': 'Bell Pepper',
    'berry': 'Berries',
    'beverage': 'Beverage',
    'bread': 'Bread',
    'broccoli': 'Broccoli',
    'brownie': 'Brownies',
    'brussels_sprouts': 'Brussels Sprouts',
    'burrito': 'Burrito',
    'butter': 'Butter',
    'cabbage': 'Cabbage',
    'cake': 'Cake',
    'candy': 'Candy',
    'cantaloupe': 'Cantaloupe',
    'carrot': 'Carrot',
    'cauliflower': 'Cauliflower',
    'celery': 'Celery',
    'cereal': 'Cereal',
    'cheese': 'Cheese',
    'cherry': 'Cherries',
    'chicken': 'Chicken',
    'chili_pepper': 'Chili Pepper',
    'chocolate': 'Chocolate',
    'citrus_fruit': 'Citrus',
    'coconut': 'Coconut',
    'coffee': 'Coffee',
    'cookie': 'Cookies',
    'corn': 'Corn',
    'crab': 'Crab',
    'cracker': 'Crackers',
    'cream': 'Cream',
    'cucumber': 'Cucumber',
    'cupcake': 'Cupcakes',
    'dairy': 'Dairy',
    'dessert': 'Dessert',
    'doughnut': 'Donuts',
    'egg': 'Eggs',
    'eggplant': 'Eggplant',
    'fast_food': 'Prepared Food',
    'fish': 'Fish',
    'flour': 'Flour',
    'food': 'Food Item',
    'french_fries': 'French Fries',
    'fruit': 'Fruit',
    'garlic': 'Garlic',
    'grape': 'Grapes',
    'grapefruit': 'Grapefruit',
    'green_bean': 'Green Beans',
    'grocery': 'Grocery Item',
    'ham': 'Ham',
    'hamburger': 'Hamburger',
    'honey': 'Honey',
    'hot_dog': 'Hot Dog',
    'ice_cream': 'Ice Cream',
    'juice': 'Juice',
    'kale': 'Kale',
    'kiwi': 'Kiwi',
    'lasagna': 'Lasagna',
    'leek': 'Leek',
    'lemon': 'Lemon',
    'lettuce': 'Lettuce',
    'lime': 'Lime',
    'lobster': 'Lobster',
    'mango': 'Mango',
    'meat': 'Meat',
    'melon': 'Melon',
    'milk': 'Milk',
    'mushroom': 'Mushrooms',
    'mussel': 'Mussels',
    'noodle': 'Noodles',
    'nut': 'Nuts',
    'oatmeal': 'Oatmeal',
    'olive': 'Olives',
    'olive_oil': 'Olive Oil',
    'onion': 'Onion',
    'orange': 'Orange',
    'oyster': 'Oysters',
    'pancake': 'Pancakes',
    'pasta': 'Pasta',
    'pastry': 'Pastry',
    'pea': 'Peas',
    'peach': 'Peach',
    'peanut': 'Peanuts',
    'pear': 'Pear',
    'pepper': 'Pepper',
    'pickle': 'Pickles',
    'pie': 'Pie',
    'pineapple': 'Pineapple',
    'pizza': 'Pizza',
    'plum': 'Plum',
    'pomegranate': 'Pomegranate',
    'popcorn': 'Popcorn',
    'pork': 'Pork',
    'potato': 'Potato',
    'poultry': 'Poultry',
    'pretzel': 'Pretzels',
    'produce': 'Produce',
    'pumpkin': 'Pumpkin',
    'quinoa': 'Quinoa',
    'radish': 'Radish',
    'raspberry': 'Raspberries',
    'rice': 'Rice',
    'salad': 'Salad',
    'salmon': 'Salmon',
    'sandwich': 'Sandwich',
    'sauce': 'Sauce',
    'sausage': 'Sausage',
    'seafood': 'Seafood',
    'shrimp': 'Shrimp',
    'snack': 'Snack',
    'soda': 'Soda',
    'soup': 'Soup',
    'soy': 'Soy',
    'spaghetti': 'Spaghetti',
    'spinach': 'Spinach',
    'squash': 'Squash',
    'steak': 'Steak',
    'strawberry': 'Strawberries',
    'sugar': 'Sugar',
    'sushi': 'Sushi',
    'sweet_potato': 'Sweet Potato',
    'taco': 'Tacos',
    'tea': 'Tea',
    'tomato': 'Tomato',
    'tortilla': 'Tortillas',
    'tuna': 'Tuna',
    'turkey': 'Turkey',
    'vegetable': 'Vegetables',
    'waffle': 'Waffles',
    'watermelon': 'Watermelon',
    'wine': 'Wine',
    'yogurt': 'Yogurt',
    'yolk': 'Eggs',
    'zucchini': 'Zucchini',
  };

  /// Broad labels get a confidence penalty (still useful as hints).
  static const Set<String> _broadLabels = {
    'food',
    'fruit',
    'vegetable',
    'produce',
    'dairy',
    'meat',
    'seafood',
    'beverage',
    'snack',
    'dessert',
    'grocery',
    'baked_goods',
    'fast_food',
    'poultry',
  };

  /// Returns a mapped grocery name, or null if not a food label.
  static MappedLabel? mapIdentifier(String identifier, double confidence) {
    if (confidence < minConfidence) return null;
    final key = identifier.trim().toLowerCase();
    if (key.isEmpty || _blocklist.contains(key)) return null;

    final display = _foodLabels[key];
    if (display == null) {
      // Unknown identifier — accept if it looks food-related (no underscore junk).
      if (key.contains('food') || key.contains('fruit') || key.contains('veg')) {
        return MappedLabel(
          name: _titleCase(key.replaceAll('_', ' ')),
          confidence: confidence * 0.6,
          source: 'vision_unknown',
        );
      }
      return null;
    }

    var adjusted = confidence;
    if (_broadLabels.contains(key)) adjusted *= 0.65;

    return MappedLabel(
      name: display,
      confidence: adjusted,
      source: 'vision_label',
    );
  }

  /// ML Kit image labeling uses human-readable labels (e.g. "Food", "Tomato").
  static MappedLabel? mapMlKitLabel(String label, double confidence) {
    if (confidence < minConfidence) return null;
    final norm = label.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    if (norm.isEmpty || _blocklist.contains(norm)) return null;

    final fromMap = mapIdentifier(norm, confidence);
    if (fromMap != null) return fromMap;

    // Direct title-case fallback for readable ML Kit labels.
    final lower = label.trim().toLowerCase();
    if (_isLikelyFoodWord(lower)) {
      return MappedLabel(
        name: _titleCase(label.trim()),
        confidence: confidence * 0.7,
        source: 'mlkit_label',
      );
    }
    return null;
  }

  static bool _isLikelyFoodWord(String lower) {
    const hints = [
      'food',
      'fruit',
      'vegetable',
      'meat',
      'dairy',
      'drink',
      'beverage',
      'snack',
      'bread',
      'milk',
      'cheese',
      'egg',
      'rice',
      'pasta',
      'sauce',
      'bean',
      'nut',
      'fish',
      'chicken',
      'beef',
      'pork',
      'salad',
      'soup',
      'cereal',
      'juice',
      'coffee',
      'tea',
      'water',
      'oil',
      'spice',
      'herb',
      'berry',
      'citrus',
      'leafy',
      'root',
      'grain',
      'baked',
      'frozen',
      'canned',
      'organic',
      'fresh',
    ];
    return hints.any(lower.contains);
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r'\s+'))
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class MappedLabel {
  const MappedLabel({
    required this.name,
    required this.confidence,
    required this.source,
  });

  final String name;
  final double confidence;
  final String source;
}
