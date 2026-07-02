// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Sous Chef';

  @override
  String get next => 'Next';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get refresh => 'Refresh';

  @override
  String get getDifferentRecipes => 'Different recipes';

  @override
  String get guestQuotaEachGenerationCounts =>
      'Guests get two recipe generations per UTC day. Each new batch counts as one—including when loading different suggestions—until you sign up.';

  @override
  String get recipePreferencesOptionalHint =>
      'Optional: what should change this time (e.g. quicker, vegetarian, bolder flavor)?';

  @override
  String get generateNewRecipeBatch => 'Generate new batch';

  @override
  String get keepAndAddRecipes => 'Keep these and load more below';

  @override
  String get fetchRecipes => 'Fetching Recipes...';

  @override
  String get fetchMoreRecipes => 'Fetch More Recipes';

  @override
  String get editPreferences => 'Edit Preferences';

  @override
  String get recipeInstructions => 'Recipe Instructions';

  @override
  String get nutritionalValue => 'Nutritional Value';

  @override
  String get nutritionalValueOfDish => 'Nutritional Value of Dish';

  @override
  String get recipeDescription => 'Recipe Description';

  @override
  String get description => 'Description';

  @override
  String get sendingTastyRecipes => 'Sending some tasty recipes your way…';

  @override
  String get recipeLoadingPhrase0 => 'Sending something delicious your way…';

  @override
  String get recipeLoadingPhrase1 => 'Turning cravings into plates…';

  @override
  String get recipeLoadingPhrase2 => 'Tasting ideas before you chop an onion.';

  @override
  String get recipeLoadingPhrase3 =>
      'Gathering spice, heat, and a little swagger.';

  @override
  String get recipeLoadingPhrase4 => 'Your kitchen glow-up starts right now.';

  @override
  String get recipeLoadingPhrase5 => 'Pairing flavors so you don\'t have to.';

  @override
  String get recipeLoadingPhrase6 => 'Simmering something worth the wait…';

  @override
  String get recipeLoadingPhrase7 => 'Sharpening the menu in your imagination.';

  @override
  String get recipeLoadingPhrase8 =>
      'Almost there—great meals begin with curiosity.';

  @override
  String get recipeLoadingPhrase9 =>
      'Whisking together comfort and pinch of bold.';

  @override
  String get recipeLoadingPhrase10 =>
      'From spark to spatula—we\'re getting there.';

  @override
  String get recipeLoadingStreamingExtra0 =>
      'Streaming recipes—first ones land shortly.';

  @override
  String get recipeLoadingStreamingExtra1 =>
      'Hang tight; results are bubbling up.';

  @override
  String get letsCookSomethingNice => 'Let\'s cook something nice together';

  @override
  String get whatDoYouFeelLikeEating => 'What can I help you with today?';

  @override
  String get pantryStaples =>
      'Tap to Add Items in your Pantry for better suggestions';

  @override
  String get pantryStaplesDialogTitle => 'Pantry staples';

  @override
  String get pantryStaplesInfo =>
      'Click on any of the following items found in your pantry and I will suggest recipes accordingly.';

  @override
  String get pantryStaplesInfoIconTooltip => 'About pantry staples';

  @override
  String get pantrySuggestionsTitle => 'Suggestions';

  @override
  String get usualCuisinesHeading => 'Cuisines you usually cook';

  @override
  String get usualCuisinesPickerHint =>
      'Pick one or more to personalize pantry suggestions.';

  @override
  String get suggestionsTapToChooseCuisines =>
      'Tap to choose cuisines you usually cook';

  @override
  String get nothingSelected => 'Nothing Selected';

  @override
  String get homeSearchSettingsSheetTitle => 'Your Recipe Preferences';

  @override
  String get homeSearchSettingsDietsHeading => 'Diet Preferences';

  @override
  String get homeSearchSettingsDietsHint =>
      'Select all styles that describe how you eat. These sync to your profile.';

  @override
  String get homeSearchSettingsAllergensHeading => 'Allergens & intolerances';

  @override
  String get homeSearchSettingsAllergensHint =>
      'Ingredients to steer clear of where possible.';

  @override
  String get homeSearchSettingsAllergenNotesLabel => 'Notes (optional)';

  @override
  String get homeSearchSettingsPreferredCuisinesHeading => 'Preferred cuisines';

  @override
  String get homeSearchSettingsPreferredCuisinesHint =>
      'Cuisines you usually want—separate from a one-off \"tonight\" pick on Create Recipes.';

  @override
  String get homeSearchSettingsCookingProficiencyHeading =>
      'Cooking proficiency';

  @override
  String get homeSearchSettingsCookingProficiencyHint =>
      'Comfort and roughly how much time you like to spend cooking.';

  @override
  String get howToUse => 'How to use';

  @override
  String get tutorialDrawerSubtitle => 'Tips and walkthrough';

  @override
  String get tutorialScreenTitle => 'How to use Sous Chef';

  @override
  String get tutorialOverviewTitle => 'Get around the app';

  @override
  String get tutorialOverviewBody =>
      'The bottom bar has five tabs: Home for quick ideas and your pantry, Create Recipes for a step-by-step questionnaire (mood, diet, cuisine, cooking time), Grocery for your shopping list, Import to bring in recipes from links, text, or photos, and Saved for recipes you keep for yourself.';

  @override
  String get tutorialCreateRecipesTitle => 'Creating recipes';

  @override
  String get tutorialCreateRecipesBody =>
      'On Home, describe what you want under \"What do you feel like eating?\" and/or add pantry items, then tap the forward arrow to generate recipes. On Create Recipes, answer each question and tap Next until recipes are generated. Tap a recipe in the list to see details and instructions.';

  @override
  String get tutorialPantryTitle => 'Pantry';

  @override
  String get tutorialPantryBody =>
      'Under Cuisines you usually cook, pick cuisines so suggestions match your cooking. Tap Add pantry items to search staples, pick suggested chips, or add a custom item. Selected items appear as green pills; tap a pill to remove it. The info icon explains how staples help.';

  @override
  String get tutorialImportTitle => 'Import recipes';

  @override
  String get tutorialImportBody =>
      'Open the Import tab to add recipes you already have elsewhere. Import from links pastes a URL from the web or social and extracts the recipe fields. Paste recipes accepts full recipe text or a social caption. Scan recipes uses your camera to read a cookbook page or recipe card (on-device OCR on phones). Review the result, then save it to your collection.';

  @override
  String get tutorialFavoritesTitle => 'Saved and favorites';

  @override
  String get tutorialFavoritesBody =>
      'Use the bookmark to save a recipe to your list. Use the heart to favorite it publicly and help it trend. Open the Saved tab for your private list. Sign up to sync to your account.';

  @override
  String get appMenuTooltip => 'App menu';

  @override
  String get showMeAround => 'Show me around';

  @override
  String get showMeInApp => 'Show me in the app';

  @override
  String get skip => 'Skip';

  @override
  String get coachStepNavTitle => 'Five tabs to cook and shop';

  @override
  String get coachStepNavBody =>
      'Use Home for quick ideas and pantry, Create Recipes for the full questionnaire, Grocery for your list, Import to add recipes from elsewhere, and Saved for your private recipe list.';

  @override
  String get coachStepGetRecipesTitle => 'Get recipes';

  @override
  String get coachStepGetRecipesBody =>
      'Describe what you want (optional), add pantry items if you like, then tap the forward arrow to generate recipes.';

  @override
  String get coachStepAddPantryTitle => 'Your pantry';

  @override
  String get coachStepAddPantryBody =>
      'Add ingredients so suggestions match what you have. You can also tap suggestion chips below.';

  @override
  String get coachStepFavoritesTitle => 'Saved recipes';

  @override
  String get coachStepFavoritesBody =>
      'Recipes you bookmark (save) appear here. Sign up from guest mode to sync to your account.';

  @override
  String get coachStepImportLinksTitle => 'Import from links';

  @override
  String get coachStepImportLinksBody =>
      'Paste a URL from the web or social — we\'ll pull out the recipe fields for you.';

  @override
  String get coachStepImportPasteTitle => 'Paste recipes';

  @override
  String get coachStepImportPasteBody =>
      'Have the text already? Drop the full recipe or caption here and we\'ll structure it.';

  @override
  String get coachStepImportScanTitle => 'Scan recipes';

  @override
  String get coachStepImportScanBody =>
      'Photograph a cookbook page or recipe card. On your phone we read the text with on-device OCR.';

  @override
  String get groceryListTitle => 'Grocery list';

  @override
  String get groceryListDrawer => 'Grocery list';

  @override
  String get groceryEmptyHint =>
      'Items you add from a recipe or with + will show up here. Open a recipe and choose what you still need to buy.';

  @override
  String get groceryAddItem => 'Add item';

  @override
  String get groceryEditItem => 'Edit item';

  @override
  String get groceryFieldName => 'Name';

  @override
  String get groceryNameSearchHint => 'e.g. Garlic';

  @override
  String get groceryGroupOther => 'Other items';

  @override
  String get groceryGroupUnnamedRecipe => 'Recipe';

  @override
  String get groceryViewAllIngredients => 'All ingredients';

  @override
  String get groceryViewPerRecipe => 'Per recipe';

  @override
  String groceryIngredientsForRecipe(String recipeTitle) {
    return 'Ingredients needed for $recipeTitle';
  }

  @override
  String get groceryFieldQuantity => 'Quantity';

  @override
  String get groceryFieldUnit => 'Unit';

  @override
  String get groceryFieldQuantityOptional => 'Quantity (optional)';

  @override
  String get groceryFieldUnitOptional => 'Unit (optional)';

  @override
  String get groceryFieldNoteOptional => 'Note (optional)';

  @override
  String get groceryShareList => 'Share list';

  @override
  String get groceryCopyList => 'Copy list';

  @override
  String get groceryShareStillNeed => 'Share items still needed';

  @override
  String get groceryCopyStillNeed => 'Copy items still needed';

  @override
  String get groceryShareSubject => 'Sous Chef — Grocery list';

  @override
  String get groceryCopied => 'List copied to clipboard';

  @override
  String get groceryNothingLeftToBuy => 'No unchecked items left to share';

  @override
  String get groceryClearChecked => 'Clear checked';

  @override
  String get groceryRemovedChecked => 'Removed checked items';

  @override
  String get recipeAddedToGroceryList => 'Added to grocery list';

  @override
  String get cookFlowAddUncheckedToGrocery =>
      'Add still needed to grocery list';

  @override
  String get groceryPantryScanTitle => 'Scan pantry';

  @override
  String get groceryPantryScanTooltip => 'Scan pantry or fridge';

  @override
  String get groceryPantryScanSubtitle =>
      'Take a clear photo. We will suggest items—tap ✓ to add to your pantry or ℹ to edit or dismiss.';

  @override
  String get groceryPantryScanSubtitleOnDevice =>
      'Take a clear photo. On your phone we analyze it on-device—nothing is uploaded. Tap ✓ to add to your pantry.';

  @override
  String get groceryPantryScanTakePhoto => 'Camera';

  @override
  String get groceryPantryScanChoosePhoto => 'Gallery';

  @override
  String get groceryPantryScanWorking => 'Analyzing photo…';

  @override
  String get groceryPantryScanWorkingOnDevice =>
      'Analyzing photo on your device…';

  @override
  String get groceryPantryScanReviewHeading => 'Review detected items';

  @override
  String get groceryPantryScanLooksLike => 'Looks like';

  @override
  String get groceryPantryScanOtherPossibilities => 'Other possibilities';

  @override
  String get groceryPantryScanScanAgain => 'Scan again';

  @override
  String get groceryPantryScanScanFromPhoto => 'Scan from photo';

  @override
  String get groceryPantryScanAddToPantry => 'Add to pantry';

  @override
  String get groceryPantryScanEditItem => 'Edit item name';

  @override
  String get groceryPantryScanDismissItem => 'Dismiss';

  @override
  String get groceryPantryScanAcceptTooltip => 'Add to pantry';

  @override
  String get groceryPantryScanEditTooltip => 'Edit or dismiss';

  @override
  String get groceryPantryScanConfidence => 'Confidence';

  @override
  String get groceryPantryScanRemoveRow => 'Remove';

  @override
  String get groceryPantryScanAddSelected => 'Add to pantry';

  @override
  String get groceryPantryScanSignInRequired =>
      'Sign in to scan your pantry or refrigerator.';

  @override
  String get groceryPantryScanNoItemsDetected =>
      'No ingredients were detected in that photo. Try better light, a wider shot, or add items manually.';

  @override
  String get groceryPantryScanSourceLabel => 'Pantry scan';

  @override
  String groceryPantryScanAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items to your pantry',
      one: 'Added 1 item to your pantry',
    );
    return '$_temp0';
  }

  @override
  String get groceryPantryScanAddedOne => 'Added to your pantry';

  @override
  String get importRecipeTabTitle => 'Import';

  @override
  String get importHubTileLinks => 'Import from links';

  @override
  String get importHubTilePaste => 'Paste recipes';

  @override
  String get importHubTileScan => 'Scan recipes';

  @override
  String get importRecipeSignInRequired =>
      'Sign in to import recipes from links, text, or photos.';

  @override
  String get importRecipeFromLinkHint => 'Paste any Web / Social Media link';

  @override
  String get importRecipePasteHint => 'Paste caption or recipe…';

  @override
  String get importRecipeExtract => 'Extract';

  @override
  String get importRecipeBusy => 'Reading recipe…';

  @override
  String get importRecipeNeedUrl => 'Paste a link first';

  @override
  String get importRecipeNeedMoreText => 'Paste a bit more text';

  @override
  String get importRecipeOcrEmpty =>
      'No readable text in that photo. Try brighter light, closer crop, or paste the recipe.';

  @override
  String get importRecipeWebScanUnsupported =>
      'Photo import uses on-device OCR in the iOS/Android app. Paste recipe text instead.';

  @override
  String get savedListSegmentCreated => 'Created';

  @override
  String get savedListSegmentImported => 'Imported';

  @override
  String get savedListEmptyCreated => 'No created recipes here yet.';

  @override
  String get savedListEmptyImported => 'No imported recipes here yet.';

  @override
  String get howAreYouFeelingToday => 'How are you feeling today?';

  @override
  String get moodHappyExcited => 'Happy/Excited';

  @override
  String get moodSadTired => 'Sad/Tired';

  @override
  String get moodNotHungry => 'Not Hungry';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodFeelingLucky => 'I am feeling lucky! (Suggest any recipe)';

  @override
  String get moodAngry => 'Angry';

  @override
  String get moodConfused => 'Confused';

  @override
  String get doYouHaveDietaryRestrictions =>
      'Do you have any Dietary Restrictions?';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescitarian => 'Pescitarian';

  @override
  String get dietNonVegetarianWithoutRedMeat =>
      'Non Vegetarian Without Red Meat';

  @override
  String get dietNonVegetarianWithRedMeat =>
      'Non Vegetarian with no restrictions';

  @override
  String get dietNutFree => 'No Nuts in my food.';

  @override
  String get dietPaleo => 'Paleo';

  @override
  String get dietKeto => 'Keto';

  @override
  String get dietGlutenFree => 'Gluten Free';

  @override
  String get dietNoRestrictions => 'No Restrictions';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietKosher => 'Kosher';

  @override
  String get whatCuisineDoYouFeelLike =>
      'What Cuisine do you feel like eating today?';

  @override
  String get cuisineIndian => 'Indian';

  @override
  String get cuisineMexican => 'Mexican';

  @override
  String get cuisineChinese => 'Chinese';

  @override
  String get cuisineThai => 'Thai';

  @override
  String get cuisineKorean => 'Korean';

  @override
  String get cuisineItalian => 'Italian';

  @override
  String get cuisineAmerican => 'American';

  @override
  String get cuisineSurpriseMe => 'Surprise Me with anything!';

  @override
  String get cuisinePopular => 'Popular';

  @override
  String get howMuchTimeCooking =>
      'How much time do you like to spend on Cooking?';

  @override
  String get cookingUnder10Min => '< 10 Minutes';

  @override
  String get cookingTenTo30Min => '10 – 30 Minutes';

  @override
  String get cookingThirtyTo60Min => '30 – 60 Minutes';

  @override
  String get cookingOver60Min => '> 60 Minutes';

  @override
  String get cookingNotParticular => 'Not Particular';

  @override
  String get allergenMilkDairy => 'Milk / dairy';

  @override
  String get allergenEggs => 'Eggs';

  @override
  String get allergenFish => 'Fish';

  @override
  String get allergenShellfish => 'Shellfish';

  @override
  String get allergenPeanuts => 'Peanuts';

  @override
  String get allergenTreeNuts => 'Tree nuts';

  @override
  String get allergenWheatGluten => 'Wheat / gluten';

  @override
  String get allergenSoy => 'Soy';

  @override
  String get allergenSesame => 'Sesame';

  @override
  String get allergenMustard => 'Mustard';

  @override
  String get allergenSulfites => 'Sulfites';

  @override
  String get medicalDisclaimer =>
      'Recipes are generated by AI for inspiration only. They are not verified for food allergies or medical diets. Always check ingredients and labels yourself if you have severe allergies or dietary requirements.';

  @override
  String get mealPlanTitle => 'Meal planner';

  @override
  String get mealPlanDrawer => 'Meal planner';

  @override
  String get mealPlanHomePrompt =>
      'Want help planning your meals? Try out our Meal Planner';

  @override
  String get mealPlanHomeCta => 'Try Meal Planner';

  @override
  String get mealPlanHubSubtitle =>
      'Plan meals from your pantry and budget. We suggest recipes and what to buy.';

  @override
  String get mealPlanStartNew => 'Plan my week';

  @override
  String get mealPlanResume => 'View last plan';

  @override
  String get mealPlanWizardTitle => 'Build your plan';

  @override
  String get mealPlanStepDiet => 'Diet goals';

  @override
  String get mealPlanStepCuisines => 'Cuisines to try';

  @override
  String get mealPlanStepMeals => 'Meals to plan';

  @override
  String get mealPlanStepDays => 'Days to plan';

  @override
  String get mealPlanStepPantry => 'Ingredients you have';

  @override
  String get mealPlanStepBudget => 'Weekly grocery budget';

  @override
  String get mealPlanGenerate => 'Generate plan';

  @override
  String get mealPlanGenerating => 'Planning your meals…';

  @override
  String get mealPlanFreeDayLimit =>
      'Free plans include up to 3 days. Upgrade for a full week.';

  @override
  String get mealPlanPremiumDays => 'Full week (Premium)';

  @override
  String get mealPlanMissingTitle => 'Still need to buy';

  @override
  String get mealPlanAddToGrocery => 'Add selected to grocery list';

  @override
  String get mealPlanCopyList => 'Copy shopping list';

  @override
  String get mealPlanShopInstacart => 'Shop with Instacart';

  @override
  String get mealPlanInstacartTitle => 'Instacart — coming soon';

  @override
  String get mealPlanInstacartBody =>
      'We\'re finishing our Instacart integration. For now, add items to your grocery list or copy the list to shop in your favorite app.';

  @override
  String get mealPlanBudgetSummary => 'Estimated cost';

  @override
  String get mealPlanOverBudget =>
      'Estimated total is above your weekly budget.';

  @override
  String get mealPlanRegenerate => 'Try another recipe';

  @override
  String get mealPlanViewRecipe => 'View recipe';

  @override
  String get mealPlanBreakfast => 'Breakfast';

  @override
  String get mealPlanLunch => 'Lunch';

  @override
  String get mealPlanDinner => 'Dinner';

  @override
  String get mealPlanMon => 'Mon';

  @override
  String get mealPlanTue => 'Tue';

  @override
  String get mealPlanWed => 'Wed';

  @override
  String get mealPlanThu => 'Thu';

  @override
  String get mealPlanFri => 'Fri';

  @override
  String get mealPlanSat => 'Sat';

  @override
  String get mealPlanSun => 'Sun';

  @override
  String get createRecipesPreferencesTitle => 'Create Recipes preferences';

  @override
  String get searchHeadlineBasedOnCustom => 'Based on what you asked for';

  @override
  String get searchHeadlineLuckyMode => 'Variety picks (lucky mode)';

  @override
  String get searchHeadlineQuestionnaire =>
      'Using your questionnaire and pantry choices';

  @override
  String get searchHeadlineCreateRecipes =>
      'Using your Create Recipes preferences';

  @override
  String get searchHeadlineSavedPreferences => 'Using your saved preferences';

  @override
  String searchDetailMood(String value) {
    return 'Mood: $value';
  }

  @override
  String searchDetailDiet(String value) {
    return 'Diet: $value';
  }

  @override
  String searchDetailCuisine(String value) {
    return 'Cuisine: $value';
  }

  @override
  String searchDetailPreferredCuisines(String value) {
    return 'Preferred cuisines: $value';
  }

  @override
  String searchDetailTime(String value) {
    return 'Time: $value';
  }

  @override
  String searchDetailCookingProficiency(String value) {
    return 'Cooking proficiency: $value';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get dismiss => 'Dismiss';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Meet your Sous Chef';

  @override
  String get onboardingWelcomeSubtitle =>
      'Recipes built around what you eat and what you have.';

  @override
  String get onboardingWelcomeCta => 'Let\'s personalize';

  @override
  String get onboardingDietTitle => 'How do you usually eat?';

  @override
  String get onboardingDietSubtitle =>
      'Pick all that apply. We\'ll tailor every recipe.';

  @override
  String get onboardingAllergiesTitle => 'Anything we should avoid?';

  @override
  String get onboardingAllergiesSubtitle =>
      'We\'ll steer clear of these ingredients when we can.';

  @override
  String get onboardingAllergiesNone => 'None';

  @override
  String get onboardingAllergiesAddNotes => 'Add notes (optional)';

  @override
  String get onboardingCuisinesTitle => 'What flavors do you love?';

  @override
  String get onboardingCuisinesSubtitle =>
      'Choose up to three — we\'ll prioritize these cuisines.';

  @override
  String onboardingCuisinesSelectedCount(int count, int max) {
    return '$count of $max selected';
  }

  @override
  String get onboardingSummaryTitle => 'Your kitchen profile';

  @override
  String get onboardingSummarySubtitle =>
      'Here\'s what Sous Chef will remember about you.';

  @override
  String onboardingSummaryDietLine(String value) {
    return 'Diet: $value';
  }

  @override
  String onboardingSummaryAllergiesLine(String value) {
    return 'Avoid: $value';
  }

  @override
  String onboardingSummaryCuisinesLine(String value) {
    return 'Loves: $value';
  }

  @override
  String get onboardingSummaryNoAllergens => 'No allergens selected';

  @override
  String get onboardingSummaryPreviewHint => 'Tonight Sous Chef might suggest…';

  @override
  String get onboardingSummaryPreviewPlaceholder =>
      'A personalized recipe just for you';

  @override
  String get onboardingPaywallTitle => 'Ready to cook?';

  @override
  String get onboardingPaywallSubtitle =>
      'Premium unlocks unlimited recipes, pantry scan, and full meal planning.';

  @override
  String get onboardingPaywallBenefitUnlimited =>
      'Unlimited AI recipe generations';

  @override
  String get onboardingPaywallBenefitNoAds => 'Pantry scan from photos';

  @override
  String get onboardingPaywallBenefitMealPlan => 'Full-week meal planner';

  @override
  String onboardingPaywallSubscribe(String price) {
    return 'Start Premium — $price/mo';
  }

  @override
  String get onboardingPaywallSkip => 'Continue with free plan';

  @override
  String get onboardingPaywallRestore => 'Restore purchases';

  @override
  String get onboardingFirstPromptHint =>
      'Tap the search bar to ask for your first recipe';

  @override
  String get freeTierQuotaMessage =>
      'Free plan includes up to 3 recipe generations per day. Upgrade for unlimited recipes.';

  @override
  String get freeTierImportQuotaMessage =>
      'Free plan includes 1 recipe import per day. Upgrade for unlimited imports.';

  @override
  String dailyCreditsUsed(int used, int total) {
    return '$used/$total Credits used';
  }
}
