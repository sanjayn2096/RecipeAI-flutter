import '../services/session_manager.dart';

/// Builds Gemini prompt from user preferences. Extracted from ViewModel for testability.
class PromptBuilder {
  PromptBuilder({required SessionManager sessionManager})
      : _session = sessionManager;

  final SessionManager _session;

  static const String _recipeFormat = '''
Recipe = {'recipeId': uuid, 'recipeName': string, 'imageUrl': String, 'ingredients': String, 'instructions' : String, 'cookingTime' : String, 'cuisine' : String, 'nutritionalValue':NutritionalValue}
NutritionalValue should be an object which has mandatory fields like 'calories' : String, 'protein': String , 'carbs' : String, 'fat' : String, 'vitamins' : String, 'numberOfServings' : Int
Calories should be in the format 'x' kcal. Protein, Fat, Carbs, Vitamins should be in grams. output should be like 'x' g. If Anything is not defined, just output N/A
Return Array<Recipe>. The ingredients and instructions should be in bullet points.
Mention the ingredients which are optional or replacements. Provide the nutritional value, how much calories per serving of the dish
Find a suitable image from the internet for this recipe and give me a public image URL for it. Make sure the image URL is accessible before giving it to me.''';

  String build() {
    final customPreference = _session.getPreference('customPreference') ?? '';
    if (customPreference.isNotEmpty) {
      return "You are my recipe book. I feel Like cooking this, $customPreference. Suggest some recipes for me accordingly. "
          "Output the recipes in this format. $_recipeFormat";
    }
    final mood = _session.getMood() ?? 'lucky';
    if (mood == 'I am feeling lucky! (Suggest any recipe)') {
      return "You are my recipe book. I'm feeling Lucky today, please suggest me any recipe. "
          "Output the recipes in this format. $_recipeFormat";
    }
    final diet = _session.getDietRestrictions() ?? 'No Diet Restrictions';
    final cuisine = _session.getCuisine() ?? 'No Cuisine Selected';
    final cooking = _session.getCookingPreference() ?? 'No Cooking Preferences';
    return "You are my recipe book. Suggest some recipes for me based on the following preferences. "
        "I am feeling: $mood, I have the following diet restrictions: $diet, "
        "I prefer spending $cooking time on cooking and I feel like eating this cuisine: $cuisine. "
        "Output the recipes in this format. $_recipeFormat "
        "What image you gave me was not correct give me a different one.";
  }
}
