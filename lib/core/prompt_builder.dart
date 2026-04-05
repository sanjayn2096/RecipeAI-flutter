import '../services/session_manager.dart';

/// Builds the recipe-generation prompt for the backend from user preferences.
class PromptBuilder {
  PromptBuilder({required SessionManager sessionManager})
      : _session = sessionManager;

  final SessionManager _session;

  static const String _recipeFormat = '''
Each recipe object MUST include these fields (use JSON keys exactly as shown):
- recipeId: String — a unique id for this recipe (use a UUID string, e.g. lowercase hex with dashes).
- recipeName: String
- imageUrl: String
- ingredients: String
- instructions: String
- cookingTime: String
- cuisine: String
- nutritionalValue: object with calories, protein, carbs, fat, vitamins (each String), numberOfServings (Int)

Calories should be in the format 'x' kcal. Protein, Fat, Carbs, Vitamins should be in grams. output should be like 'x' g. If Anything is not defined, just output N/A
Return Array<Recipe>. The ingredients and instructions should be in bullet points.
Mention the ingredients which are optional or replacements. Provide the nutritional value, how much calories per serving of the dish
Find a suitable image from the internet for this recipe and give me a public image URL for it. Make sure the image URL is accessible before giving it to me.''';

  static const String _rawJsonOnly = '''
Respond with only raw JSON. Do not include markdown, code blocks, no "Here is the JSON", and no text before or after the JSON array.''';

  /// When [getIngredients] is non-empty, prepend this (joined with commas).
  String _ingredientsPromptPrefix() {
    final ingredients = _session.getIngredients();
    if (ingredients.isEmpty) return '';
    final joined = ingredients.join(', ');
    return 'I have the following ingredients, $joined suggest recipes accordingly. ';
  }

  String build() {
    final ing = _ingredientsPromptPrefix();
    final customPreference = _session.getPreference('customPreference') ?? '';
    if (customPreference.isNotEmpty) {
      if (ing.isNotEmpty) {
      return "${ing}, You are my recipe book. I feel Like cooking this, $customPreference. Suggest some recipes for me accordingly. "
          "Output the recipes in this format. $_recipeFormat and $_rawJsonOnly";
      } else {
        return "You are my recipe book. I feel Like cooking this, $customPreference. Suggest some recipes for me accordingly. "
          "Output the recipes in this format. $_recipeFormat and $_rawJsonOnly";
      }
    }
    final mood = _session.getMood() ?? 'lucky';
    if (mood == 'I am feeling lucky! (Suggest any recipe)') {
      return "${ing}, You are my recipe book. I'm feeling Lucky today, please suggest me any recipe. "
          "Output the recipes in this format. $_recipeFormat and $_rawJsonOnly";
    }
    final diet = _session.getDietRestrictions() ?? 'No Diet Restrictions';
    final cuisine = _session.getCuisine() ?? 'No Cuisine Selected';
    final cooking = _session.getCookingPreference() ?? 'No Cooking Preferences';
    return "${ing}, You are my recipe book. Suggest some recipes for me based on the following preferences. "
        "I am feeling: $mood, I have the following diet restrictions: $diet, "
        "I prefer spending $cooking time on cooking and I feel like eating this cuisine: $cuisine. "
        "Output the recipes in this format. $_recipeFormat "
        "Also $_rawJsonOnly";
  }
}
