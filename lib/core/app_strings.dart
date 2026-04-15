/// Centralized strings (replaces Android strings.xml).
class AppStrings {
  AppStrings._();

  static const String appName = 'Sous Chef';
  static const String next = 'Next';
  static const String ok = 'OK';
  static const String back = 'Back';
  static const String refresh = 'Refresh';
  static const String fetchRecipes = 'Fetching Recipes...';
  static const String fetchMoreRecipes = 'Fetch More Recipes';
  static const String editPreferences = 'Edit Preferences';
  static const String recipeInstructions = 'Recipe Instructions';
  static const String nutritionalValue = 'Nutritional Value';
  static const String nutritionalValueOfDish = 'Nutritional Value of Dish';
  static const String recipeDescription = 'Recipe Description';
  static const String description = 'Description';
  static const String sendingTastyRecipes = 'Sending some tasty recipes your way…';
  static const String letsCookSomethingNice = "Let's cook something nice today";
  static const String whatDoYouFeelLikeEating = 'What do you feel like eating?';
  static const String pantryStaples = 'Pantry staples — tap to add';
  static const String pantryStaplesDialogTitle = 'Pantry staples';
  /// Shown in the info dialog next to the pantry staples heading.
  static const String pantryStaplesInfo =
      'Click on any of the following items found in your pantry and I will suggest recipes accordingly.';
  static const String pantryStaplesInfoIconTooltip = 'About pantry staples';
  static const String nothingSelected = 'Nothing Selected';

  // Tutorial / drawer
  static const String howToUse = 'How to use';
  static const String tutorialDrawerSubtitle = 'Tips and walkthrough';
  static const String tutorialScreenTitle = 'How to use Sous Chef';
  static const String tutorialOverviewTitle = 'Get around the app';
  static const String tutorialOverviewBody =
      'The bottom bar has three tabs: Home for quick ideas and your pantry, '
      'Create Recipes for a step-by-step questionnaire (mood, diet, cuisine, cooking time), '
      'and Favorites for recipes you have saved.';
  static const String tutorialCreateRecipesTitle = 'Creating recipes';
  static const String tutorialCreateRecipesBody =
      'On Home, describe what you want under “What do you feel like eating?” and/or add pantry items, '
      'then tap Get me Recipes. On Create Recipes, answer each question and tap Next until recipes are generated. '
      'Tap a recipe in the list to see details and instructions.';
  static const String tutorialPantryTitle = 'Pantry';
  static const String tutorialPantryBody =
      'Under Cuisines you usually cook, pick cuisines so suggestions match your cooking. '
      'Tap Add pantry items to search staples, pick suggested chips, or add a custom item. '
      'Selected items appear as green pills; tap a pill to remove it. The info icon explains how staples help.';
  static const String tutorialFavoritesTitle = 'Favorites';
  static const String tutorialFavoritesBody =
      'On the recipe list, tap the heart to save or remove a favorite. Open the Favorites tab to browse saved recipes. '
      'Guest mode lets you try the app; sign up to save favorites to your account.';
  static const String appMenuTooltip = 'App menu';
  static const String showMeAround = 'Show me around';
  static const String showMeInApp = 'Show me in the app';
  static const String skip = 'Skip';
  static const String coachStepNavTitle = 'Three ways to cook';
  static const String coachStepNavBody =
      'Use Home for quick ideas and pantry, Create Recipes for the full questionnaire, '
      'and Favorites for saved recipes.';
  static const String coachStepGetRecipesTitle = 'Get recipes';
  static const String coachStepGetRecipesBody =
      'Describe what you want (optional), add pantry items if you like, then tap here to generate recipes.';
  static const String coachStepAddPantryTitle = 'Your pantry';
  static const String coachStepAddPantryBody =
      'Add ingredients so suggestions match what you have. You can also tap suggestion chips below.';
  static const String coachStepFavoritesTitle = 'Saved recipes';
  static const String coachStepFavoritesBody =
      'Recipes you heart appear here. Sign up from guest mode to sync favorites to your account.';

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
  static const String notParticular = 'Not Particular';

  static List<String> get moodOptions => [
        happyExcited,
        sadTired,
        notHungry,
        neutral,
        feelingLucky,
        angry,
        confused
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
        noRestrictions
      ];

  static List<String> get cuisineOptions => [
        indian,
        mexican,
        chinese,
        thai,
        korean,
        italian,
        american,
        surpriseMe
      ];

  static List<String> get cookingTimeOptions => [
        under10Min,
        tenTo30Min,
        thirtyTo60Min,
        over60Min,
        notParticular,
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

  /// Prior questionnaire step (mood has no previous).
  static String? previousRoute(String route) {
    switch (route) {
      case 'mood':
        return null;
      case 'dietRestrictions':
        return 'mood';
      case 'cuisinePreferences':
        return 'dietRestrictions';
      case 'cookingPreferences':
        return 'cuisinePreferences';
      default:
        return null;
    }
  }
}
