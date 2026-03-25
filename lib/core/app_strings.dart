/// Centralized strings (replaces Android strings.xml).
class AppStrings {
  AppStrings._();

  static const String appName = 'RecipeAI';
  static const String next = 'Next';
  static const String back = 'Back';
  static const String refresh = 'Refresh';
  static const String fetchRecipes = 'Fetch Recipes';
  static const String fetchMoreRecipes = 'Fetch More Recipes';
  static const String editPreferences = 'Edit Preferences';
  static const String recipeInstructions = 'Recipe Instructions';
  static const String nutritionalValue = 'Nutritional Value';
  static const String nutritionalValueOfDish = 'Nutritional Value of Dish';
  static const String recipeDescription = 'Recipe Description';
  static const String description = 'Description';
  static const String sendingTastyRecipes = 'Sending some tasty recipes your way…';
  static const String letsCookSomethingNice = "Let's help you cook Something Nice Today!";
  static const String whatDoYouFeelLikeEating = 'What do you feel like eating?';
  static const String pantryStaples = 'Pantry staples - Click to suggest recipes based on what you have.';
  static const String nothingSelected = 'Nothing Selected';

  // Mood
  static const String howAreYouFeelingToday = 'How are you feeling today?';
  static const String happyExcited = 'Happy/Excited';
  static const String sadTired = 'Sad/Tired';
  static const String notHungry = 'Not Hungry';
  static const String neutral = 'Neutral';
  static const String feelingLucky = 'I am feeling lucky! (Suggest any recipe)';
  static const String angry = 'Angry';
  static const String confused = 'Confused';

  // Diet
  static const String doYouHaveDietaryRestrictions = 'Do you have any Dietary Restrictions?';
  static const String vegetarian = 'Vegetarian';
  static const String vegan = 'Vegan';
  static const String pescitarian = 'Pescitarian';
  static const String nonVegetarianWithoutRedMeat = 'Non Vegetarian Without Red Meat';
  static const String nonVegetarianWithRedMeat = 'Non Vegetarian with no restrictions';
  static const String nutFree = 'No Nuts in my food.';
  static const String paleo = 'Paleo';
  static const String keto = 'Keto';
  static const String glutenFree = 'Gluten Free';
  static const String noRestrictions = 'No Restrictions';

  // Cuisine
  static const String whatCuisineDoYouFeelLike = 'What Cuisine do you feel like eating today?';
  static const String indian = 'Indian';
  static const String mexican = 'Mexican';
  static const String chinese = 'Chinese';
  static const String thai = 'Thai';
  static const String korean = 'Korean';
  static const String italian = 'Italian';
  static const String american = 'American';
  static const String surpriseMe = 'Surprise Me with anything!';

  // Cooking time
  static const String howMuchTimeCooking = 'How much time do you like to spend on Cooking?';
  static const String under10Min = '< 10 Minutes';
  static const String tenTo30Min = '10 – 30 Minutes';
  static const String thirtyTo60Min = '30 – 60 Minutes';
  static const String over60Min = '> 60 Minutes';

  static List<String> get moodOptions => [
        happyExcited,
        sadTired,
        notHungry,
        neutral,
        feelingLucky,
        angry,
        confused,
        nothingSelected,
      ];

  static List<String> get dietOptions => [
        vegetarian,
        vegan,
        pescitarian,
        nonVegetarianWithoutRedMeat,
        nonVegetarianWithRedMeat,
        nutFree,
        paleo,
        keto,
        glutenFree,
        noRestrictions,
        nothingSelected,
      ];

  static List<String> get cuisineOptions => [
        indian,
        mexican,
        chinese,
        thai,
        korean,
        italian,
        american,
        surpriseMe,
        nothingSelected,
      ];

  static List<String> get cookingTimeOptions => [
        under10Min,
        tenTo30Min,
        thirtyTo60Min,
        over60Min,
        nothingSelected,
      ];

  static String titleForRoute(String route) {
    switch (route) {
      case 'mood':
        return howAreYouFeelingToday;
      case 'dietRestrictions':
        return doYouHaveDietaryRestrictions;
      case 'cuisinePreferences':
        return whatCuisineDoYouFeelLike;
      case 'cookingPreferences':
        return howMuchTimeCooking;
      default:
        return '';
    }
  }

  static String? nextRoute(String route) {
    switch (route) {
      case 'mood':
        return 'dietRestrictions';
      case 'dietRestrictions':
        return 'cuisinePreferences';
      case 'cuisinePreferences':
        return 'cookingPreferences';
      case 'cookingPreferences':
        return 'recipeActivity';
      default:
        return null;
    }
  }
}
