// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Sous Chef';

  @override
  String get next => 'Siguiente';

  @override
  String get ok => 'Aceptar';

  @override
  String get back => 'Atrás';

  @override
  String get refresh => 'Actualizar';

  @override
  String get getDifferentRecipes => 'Otras recetas';

  @override
  String get guestQuotaEachGenerationCounts =>
      'Los invitados tienen dos generaciones de recetas por día UTC. Cada lote nuevo cuenta como una—incluso al cargar otras sugerencias—hasta que te registres.';

  @override
  String get recipePreferencesOptionalHint =>
      'Opcional: ¿qué debería cambiar esta vez (p. ej. más rápido, vegetariano, más intenso)?';

  @override
  String get generateNewRecipeBatch => 'Generar nuevo lote';

  @override
  String get keepAndAddRecipes => 'Conservar estas y cargar más abajo';

  @override
  String get fetchRecipes => 'Obteniendo recetas...';

  @override
  String get fetchMoreRecipes => 'Obtener más recetas';

  @override
  String get editPreferences => 'Editar preferencias';

  @override
  String get recipeInstructions => 'Instrucciones de la receta';

  @override
  String get nutritionalValue => 'Valor nutricional';

  @override
  String get nutritionalValueOfDish => 'Valor nutricional del plato';

  @override
  String get recipeDescription => 'Descripción de la receta';

  @override
  String get description => 'Descripción';

  @override
  String get sendingTastyRecipes => 'Te enviamos recetas deliciosas…';

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
  String get letsCookSomethingNice => 'Cocinemos algo rico juntos';

  @override
  String get whatDoYouFeelLikeEating => '¿En qué puedo ayudarte hoy?';

  @override
  String get pantryStaples =>
      'Toca para añadir artículos a tu despensa y obtener mejores sugerencias';

  @override
  String get pantryStaplesDialogTitle => 'Básicos de despensa';

  @override
  String get pantryStaplesInfo =>
      'Click on any of the following items found in your pantry and I will suggest recipes accordingly.';

  @override
  String get pantryStaplesInfoIconTooltip => 'About pantry staples';

  @override
  String get pantrySuggestionsTitle => 'Sugerencias';

  @override
  String get usualCuisinesHeading => 'Cocinas que sueles preparar';

  @override
  String get usualCuisinesPickerHint =>
      'Pick one or more to personalize pantry suggestions.';

  @override
  String get suggestionsTapToChooseCuisines =>
      'Tap to choose cuisines you usually cook';

  @override
  String get nothingSelected => 'Nada seleccionado';

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
  String get howToUse => 'Cómo usar';

  @override
  String get tutorialDrawerSubtitle => 'Consejos y recorrido';

  @override
  String get tutorialScreenTitle => 'Cómo usar Sous Chef';

  @override
  String get tutorialOverviewTitle => 'Muévete por la app';

  @override
  String get tutorialOverviewBody =>
      'The bottom bar has five tabs: Home for quick ideas and your pantry, Create Recipes for a step-by-step questionnaire (mood, diet, cuisine, cooking time), Grocery for your shopping list, Import to bring in recipes from links, text, or photos, and Saved for recipes you keep for yourself.';

  @override
  String get tutorialCreateRecipesTitle => 'Crear recetas';

  @override
  String get tutorialCreateRecipesBody =>
      'On Home, describe what you want under \"What do you feel like eating?\" and/or add pantry items, then tap the forward arrow to generate recipes. On Create Recipes, answer each question and tap Next until recipes are generated. Tap a recipe in the list to see details and instructions.';

  @override
  String get tutorialPantryTitle => 'Despensa';

  @override
  String get tutorialPantryBody =>
      'Under Cuisines you usually cook, pick cuisines so suggestions match your cooking. Tap Add pantry items to search staples, pick suggested chips, or add a custom item. Selected items appear as green pills; tap a pill to remove it. The info icon explains how staples help.';

  @override
  String get tutorialImportTitle => 'Importar recetas';

  @override
  String get tutorialImportBody =>
      'Open the Import tab to add recipes you already have elsewhere. Import from links pastes a URL from the web or social and extracts the recipe fields. Paste recipes accepts full recipe text or a social caption. Scan recipes uses your camera to read a cookbook page or recipe card (on-device OCR on phones). Review the result, then save it to your collection.';

  @override
  String get tutorialFavoritesTitle => 'Guardadas y favoritas';

  @override
  String get tutorialFavoritesBody =>
      'Use the bookmark to save a recipe to your list. Use the heart to favorite it publicly and help it trend. Open the Saved tab for your private list. Sign up to sync to your account.';

  @override
  String get appMenuTooltip => 'Menú de la app';

  @override
  String get showMeAround => 'Muéstrame la app';

  @override
  String get showMeInApp => 'Muéstrame en la app';

  @override
  String get skip => 'Omitir';

  @override
  String get coachStepNavTitle => 'Cinco pestañas para cocinar y comprar';

  @override
  String get coachStepNavBody =>
      'Use Home for quick ideas and pantry, Create Recipes for the full questionnaire, Grocery for your list, Import to add recipes from elsewhere, and Saved for your private recipe list.';

  @override
  String get coachStepGetRecipesTitle => 'Obtener recetas';

  @override
  String get coachStepGetRecipesBody =>
      'Describe what you want (optional), add pantry items if you like, then tap the forward arrow to generate recipes.';

  @override
  String get coachStepAddPantryTitle => 'Tu despensa';

  @override
  String get coachStepAddPantryBody =>
      'Add ingredients so suggestions match what you have. You can also tap suggestion chips below.';

  @override
  String get coachStepFavoritesTitle => 'Recetas guardadas';

  @override
  String get coachStepFavoritesBody =>
      'Recipes you bookmark (save) appear here. Sign up from guest mode to sync to your account.';

  @override
  String get coachStepImportLinksTitle => 'Importar desde enlaces';

  @override
  String get coachStepImportLinksBody =>
      'Paste a URL from the web or social — we\'ll pull out the recipe fields for you.';

  @override
  String get coachStepImportPasteTitle => 'Pegar recetas';

  @override
  String get coachStepImportPasteBody =>
      'Have the text already? Drop the full recipe or caption here and we\'ll structure it.';

  @override
  String get coachStepImportScanTitle => 'Escanear recetas';

  @override
  String get coachStepImportScanBody =>
      'Photograph a cookbook page or recipe card. On your phone we read the text with on-device OCR.';

  @override
  String get groceryListTitle => 'Lista de compras';

  @override
  String get groceryListDrawer => 'Lista de compras';

  @override
  String get groceryEmptyHint =>
      'Items you add from a recipe or with + will show up here. Open a recipe and choose what you still need to buy.';

  @override
  String get groceryAddItem => 'Añadir artículo';

  @override
  String get groceryEditItem => 'Editar artículo';

  @override
  String get groceryFieldName => 'Nombre';

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
  String get groceryShareList => 'Compartir lista';

  @override
  String get groceryCopyList => 'Copiar lista';

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
  String get groceryClearChecked => 'Borrar marcados';

  @override
  String get groceryRemovedChecked => 'Removed checked items';

  @override
  String get recipeAddedToGroceryList => 'Añadido a la lista de compras';

  @override
  String get cookFlowAddUncheckedToGrocery =>
      'Add still needed to grocery list';

  @override
  String get groceryPantryScanTitle => 'Escanear despensa';

  @override
  String get groceryPantryScanTooltip => 'Scan pantry or fridge';

  @override
  String get groceryPantryScanSubtitle =>
      'Take a clear photo. We will suggest items—tap ✓ to add to your pantry or ℹ to edit or dismiss.';

  @override
  String get groceryPantryScanSubtitleOnDevice =>
      'Take a clear photo. On your phone we analyze it on-device—nothing is uploaded. Tap ✓ to add to your pantry.';

  @override
  String get groceryPantryScanTakePhoto => 'Cámara';

  @override
  String get groceryPantryScanChoosePhoto => 'Galería';

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
  String get groceryPantryScanScanAgain => 'Escanear de nuevo';

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
  String get importRecipeTabTitle => 'Importar';

  @override
  String get importHubTileLinks => 'Importar desde enlaces';

  @override
  String get importHubTilePaste => 'Pegar recetas';

  @override
  String get importHubTileScan => 'Escanear recetas';

  @override
  String get importRecipeSignInRequired =>
      'Sign in to import recipes from links, text, or photos.';

  @override
  String get importRecipeFromLinkHint => 'Paste any Web / Social Media link';

  @override
  String get importRecipePasteHint => 'Paste caption or recipe…';

  @override
  String get importRecipeExtract => 'Extraer';

  @override
  String get importRecipeBusy => 'Leyendo receta…';

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
  String get savedListSegmentCreated => 'Creadas';

  @override
  String get savedListSegmentImported => 'Importadas';

  @override
  String get savedListEmptyCreated => 'No created recipes here yet.';

  @override
  String get savedListEmptyImported => 'No imported recipes here yet.';

  @override
  String get howAreYouFeelingToday => '¿Cómo te sientes hoy?';

  @override
  String get moodHappyExcited => 'Feliz/Emocionado';

  @override
  String get moodSadTired => 'Triste/Cansado';

  @override
  String get moodNotHungry => 'Sin hambre';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get moodFeelingLucky =>
      '¡Me siento con suerte! (Sugiere cualquier receta)';

  @override
  String get moodAngry => 'Enojado';

  @override
  String get moodConfused => 'Confundido';

  @override
  String get doYouHaveDietaryRestrictions =>
      '¿Tienes restricciones dietéticas?';

  @override
  String get dietVegetarian => 'Vegetariano';

  @override
  String get dietVegan => 'Vegano';

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
  String get dietNoRestrictions => 'Sin restricciones';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietKosher => 'Kosher';

  @override
  String get whatCuisineDoYouFeelLike => '¿Qué cocina te apetece hoy?';

  @override
  String get cuisineIndian => 'India';

  @override
  String get cuisineMexican => 'Mexicana';

  @override
  String get cuisineChinese => 'China';

  @override
  String get cuisineThai => 'Tailandesa';

  @override
  String get cuisineKorean => 'Coreana';

  @override
  String get cuisineItalian => 'Italiana';

  @override
  String get cuisineAmerican => 'Americana';

  @override
  String get cuisineSurpriseMe => '¡Sorpréndeme con cualquier cosa!';

  @override
  String get cuisinePopular => 'Popular';

  @override
  String get howMuchTimeCooking => '¿Cuánto tiempo te gusta cocinar?';

  @override
  String get cookingUnder10Min => '< 10 minutos';

  @override
  String get cookingTenTo30Min => '10 – 30 minutos';

  @override
  String get cookingThirtyTo60Min => '30 – 60 minutos';

  @override
  String get cookingOver60Min => '> 60 minutos';

  @override
  String get cookingNotParticular => 'No es particular';

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
  String get mealPlanTitle => 'Planificador de comidas';

  @override
  String get mealPlanDrawer => 'Meal planner';

  @override
  String get mealPlanHomePrompt =>
      'Want help planning your meals? Try out our Meal Planner';

  @override
  String get mealPlanHomeCta => 'Probar planificador';

  @override
  String get mealPlanHubSubtitle =>
      'Plan meals from your pantry and budget. We suggest recipes and what to buy.';

  @override
  String get mealPlanStartNew => 'Planificar mi semana';

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
  String get mealPlanBreakfast => 'Desayuno';

  @override
  String get mealPlanLunch => 'Almuerzo';

  @override
  String get mealPlanDinner => 'Cena';

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
  String get searchHeadlineLuckyMode => 'Selección variada (modo suerte)';

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
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get dismiss => 'Cerrar';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Conoce a tu Sous Chef';

  @override
  String get onboardingWelcomeSubtitle =>
      'Recetas basadas en lo que comes y lo que tienes.';

  @override
  String get onboardingWelcomeCta => 'Personalicemos';

  @override
  String get onboardingDietTitle => '¿Cómo sueles comer?';

  @override
  String get onboardingDietSubtitle =>
      'Elige todas las que correspondan. Adaptaremos cada receta.';

  @override
  String get onboardingAllergiesTitle => '¿Algo que debamos evitar?';

  @override
  String get onboardingAllergiesSubtitle =>
      'Evitaremos estos ingredientes cuando sea posible.';

  @override
  String get onboardingAllergiesNone => 'Ninguno';

  @override
  String get onboardingAllergiesAddNotes => 'Añadir notas (opcional)';

  @override
  String get onboardingCuisinesTitle => '¿Qué sabores te encantan?';

  @override
  String get onboardingCuisinesSubtitle =>
      'Elige hasta tres — priorizaremos estas cocinas.';

  @override
  String onboardingCuisinesSelectedCount(int count, int max) {
    return '$count de $max seleccionadas';
  }

  @override
  String get onboardingSummaryTitle => 'Tu perfil de cocina';

  @override
  String get onboardingSummarySubtitle =>
      'Esto es lo que Sous Chef recordará de ti.';

  @override
  String onboardingSummaryDietLine(String value) {
    return 'Dieta: $value';
  }

  @override
  String onboardingSummaryAllergiesLine(String value) {
    return 'Evitar: $value';
  }

  @override
  String onboardingSummaryCuisinesLine(String value) {
    return 'Le gusta: $value';
  }

  @override
  String get onboardingSummaryNoAllergens => 'Sin alérgenos seleccionados';

  @override
  String get onboardingSummaryPreviewHint =>
      'Esta noche Sous Chef podría sugerir…';

  @override
  String get onboardingSummaryPreviewPlaceholder =>
      'Una receta personalizada para ti';

  @override
  String get onboardingPaywallTitle => '¿Listo para cocinar?';

  @override
  String get onboardingPaywallSubtitle =>
      'Premium desbloquea recetas ilimitadas, escaneo de despensa y planificación completa.';

  @override
  String get onboardingPaywallBenefitUnlimited =>
      'Generaciones de recetas IA ilimitadas';

  @override
  String get onboardingPaywallBenefitNoAds => 'Escanear despensa desde fotos';

  @override
  String get onboardingPaywallBenefitMealPlan =>
      'Planificador semanal completo';

  @override
  String onboardingPaywallSubscribe(String price) {
    return 'Premium — $price/mes';
  }

  @override
  String get onboardingPaywallSkip => 'Continuar con plan gratuito';

  @override
  String get onboardingPaywallRestore => 'Restaurar compras';

  @override
  String get onboardingFirstPromptHint =>
      'Toca la barra de búsqueda para pedir tu primera receta';

  @override
  String get freeTierQuotaMessage =>
      'El plan gratuito incluye hasta 3 generaciones de recetas al día. Mejora para recetas ilimitadas.';

  @override
  String get freeTierImportQuotaMessage =>
      'El plan gratuito incluye 1 importación de receta al día. Mejora para importaciones ilimitadas.';

  @override
  String dailyCreditsUsed(int used, int total) {
    return '$used/$total créditos usados';
  }
}
