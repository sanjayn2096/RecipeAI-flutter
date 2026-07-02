import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sous Chef'**
  String get appName;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @getDifferentRecipes.
  ///
  /// In en, this message translates to:
  /// **'Different recipes'**
  String get getDifferentRecipes;

  /// No description provided for @guestQuotaEachGenerationCounts.
  ///
  /// In en, this message translates to:
  /// **'Guests get two recipe generations per UTC day. Each new batch counts as one—including when loading different suggestions—until you sign up.'**
  String get guestQuotaEachGenerationCounts;

  /// No description provided for @recipePreferencesOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional: what should change this time (e.g. quicker, vegetarian, bolder flavor)?'**
  String get recipePreferencesOptionalHint;

  /// No description provided for @generateNewRecipeBatch.
  ///
  /// In en, this message translates to:
  /// **'Generate new batch'**
  String get generateNewRecipeBatch;

  /// No description provided for @keepAndAddRecipes.
  ///
  /// In en, this message translates to:
  /// **'Keep these and load more below'**
  String get keepAndAddRecipes;

  /// No description provided for @fetchRecipes.
  ///
  /// In en, this message translates to:
  /// **'Fetching Recipes...'**
  String get fetchRecipes;

  /// No description provided for @fetchMoreRecipes.
  ///
  /// In en, this message translates to:
  /// **'Fetch More Recipes'**
  String get fetchMoreRecipes;

  /// No description provided for @editPreferences.
  ///
  /// In en, this message translates to:
  /// **'Edit Preferences'**
  String get editPreferences;

  /// No description provided for @recipeInstructions.
  ///
  /// In en, this message translates to:
  /// **'Recipe Instructions'**
  String get recipeInstructions;

  /// No description provided for @nutritionalValue.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Value'**
  String get nutritionalValue;

  /// No description provided for @nutritionalValueOfDish.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Value of Dish'**
  String get nutritionalValueOfDish;

  /// No description provided for @recipeDescription.
  ///
  /// In en, this message translates to:
  /// **'Recipe Description'**
  String get recipeDescription;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @sendingTastyRecipes.
  ///
  /// In en, this message translates to:
  /// **'Sending some tasty recipes your way…'**
  String get sendingTastyRecipes;

  /// No description provided for @recipeLoadingPhrase0.
  ///
  /// In en, this message translates to:
  /// **'Sending something delicious your way…'**
  String get recipeLoadingPhrase0;

  /// No description provided for @recipeLoadingPhrase1.
  ///
  /// In en, this message translates to:
  /// **'Turning cravings into plates…'**
  String get recipeLoadingPhrase1;

  /// No description provided for @recipeLoadingPhrase2.
  ///
  /// In en, this message translates to:
  /// **'Tasting ideas before you chop an onion.'**
  String get recipeLoadingPhrase2;

  /// No description provided for @recipeLoadingPhrase3.
  ///
  /// In en, this message translates to:
  /// **'Gathering spice, heat, and a little swagger.'**
  String get recipeLoadingPhrase3;

  /// No description provided for @recipeLoadingPhrase4.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen glow-up starts right now.'**
  String get recipeLoadingPhrase4;

  /// No description provided for @recipeLoadingPhrase5.
  ///
  /// In en, this message translates to:
  /// **'Pairing flavors so you don\'t have to.'**
  String get recipeLoadingPhrase5;

  /// No description provided for @recipeLoadingPhrase6.
  ///
  /// In en, this message translates to:
  /// **'Simmering something worth the wait…'**
  String get recipeLoadingPhrase6;

  /// No description provided for @recipeLoadingPhrase7.
  ///
  /// In en, this message translates to:
  /// **'Sharpening the menu in your imagination.'**
  String get recipeLoadingPhrase7;

  /// No description provided for @recipeLoadingPhrase8.
  ///
  /// In en, this message translates to:
  /// **'Almost there—great meals begin with curiosity.'**
  String get recipeLoadingPhrase8;

  /// No description provided for @recipeLoadingPhrase9.
  ///
  /// In en, this message translates to:
  /// **'Whisking together comfort and pinch of bold.'**
  String get recipeLoadingPhrase9;

  /// No description provided for @recipeLoadingPhrase10.
  ///
  /// In en, this message translates to:
  /// **'From spark to spatula—we\'re getting there.'**
  String get recipeLoadingPhrase10;

  /// No description provided for @recipeLoadingStreamingExtra0.
  ///
  /// In en, this message translates to:
  /// **'Streaming recipes—first ones land shortly.'**
  String get recipeLoadingStreamingExtra0;

  /// No description provided for @recipeLoadingStreamingExtra1.
  ///
  /// In en, this message translates to:
  /// **'Hang tight; results are bubbling up.'**
  String get recipeLoadingStreamingExtra1;

  /// No description provided for @letsCookSomethingNice.
  ///
  /// In en, this message translates to:
  /// **'Let\'s cook something nice together'**
  String get letsCookSomethingNice;

  /// No description provided for @whatDoYouFeelLikeEating.
  ///
  /// In en, this message translates to:
  /// **'What can I help you with today?'**
  String get whatDoYouFeelLikeEating;

  /// No description provided for @pantryStaples.
  ///
  /// In en, this message translates to:
  /// **'Tap to Add Items in your Pantry for better suggestions'**
  String get pantryStaples;

  /// No description provided for @pantryStaplesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Pantry staples'**
  String get pantryStaplesDialogTitle;

  /// No description provided for @pantryStaplesInfo.
  ///
  /// In en, this message translates to:
  /// **'Click on any of the following items found in your pantry and I will suggest recipes accordingly.'**
  String get pantryStaplesInfo;

  /// No description provided for @pantryStaplesInfoIconTooltip.
  ///
  /// In en, this message translates to:
  /// **'About pantry staples'**
  String get pantryStaplesInfoIconTooltip;

  /// No description provided for @pantrySuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get pantrySuggestionsTitle;

  /// No description provided for @usualCuisinesHeading.
  ///
  /// In en, this message translates to:
  /// **'Cuisines you usually cook'**
  String get usualCuisinesHeading;

  /// No description provided for @usualCuisinesPickerHint.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more to personalize pantry suggestions.'**
  String get usualCuisinesPickerHint;

  /// No description provided for @suggestionsTapToChooseCuisines.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose cuisines you usually cook'**
  String get suggestionsTapToChooseCuisines;

  /// No description provided for @nothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Nothing Selected'**
  String get nothingSelected;

  /// No description provided for @homeSearchSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Recipe Preferences'**
  String get homeSearchSettingsSheetTitle;

  /// No description provided for @homeSearchSettingsDietsHeading.
  ///
  /// In en, this message translates to:
  /// **'Diet Preferences'**
  String get homeSearchSettingsDietsHeading;

  /// No description provided for @homeSearchSettingsDietsHint.
  ///
  /// In en, this message translates to:
  /// **'Select all styles that describe how you eat. These sync to your profile.'**
  String get homeSearchSettingsDietsHint;

  /// No description provided for @homeSearchSettingsAllergensHeading.
  ///
  /// In en, this message translates to:
  /// **'Allergens & intolerances'**
  String get homeSearchSettingsAllergensHeading;

  /// No description provided for @homeSearchSettingsAllergensHint.
  ///
  /// In en, this message translates to:
  /// **'Ingredients to steer clear of where possible.'**
  String get homeSearchSettingsAllergensHint;

  /// No description provided for @homeSearchSettingsAllergenNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get homeSearchSettingsAllergenNotesLabel;

  /// No description provided for @homeSearchSettingsPreferredCuisinesHeading.
  ///
  /// In en, this message translates to:
  /// **'Preferred cuisines'**
  String get homeSearchSettingsPreferredCuisinesHeading;

  /// No description provided for @homeSearchSettingsPreferredCuisinesHint.
  ///
  /// In en, this message translates to:
  /// **'Cuisines you usually want—separate from a one-off \"tonight\" pick on Create Recipes.'**
  String get homeSearchSettingsPreferredCuisinesHint;

  /// No description provided for @homeSearchSettingsCookingProficiencyHeading.
  ///
  /// In en, this message translates to:
  /// **'Cooking proficiency'**
  String get homeSearchSettingsCookingProficiencyHeading;

  /// No description provided for @homeSearchSettingsCookingProficiencyHint.
  ///
  /// In en, this message translates to:
  /// **'Comfort and roughly how much time you like to spend cooking.'**
  String get homeSearchSettingsCookingProficiencyHint;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @tutorialDrawerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tips and walkthrough'**
  String get tutorialDrawerSubtitle;

  /// No description provided for @tutorialScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'How to use Sous Chef'**
  String get tutorialScreenTitle;

  /// No description provided for @tutorialOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Get around the app'**
  String get tutorialOverviewTitle;

  /// No description provided for @tutorialOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'The bottom bar has five tabs: Home for quick ideas and your pantry, Create Recipes for a step-by-step questionnaire (mood, diet, cuisine, cooking time), Grocery for your shopping list, Import to bring in recipes from links, text, or photos, and Saved for recipes you keep for yourself.'**
  String get tutorialOverviewBody;

  /// No description provided for @tutorialCreateRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating recipes'**
  String get tutorialCreateRecipesTitle;

  /// No description provided for @tutorialCreateRecipesBody.
  ///
  /// In en, this message translates to:
  /// **'On Home, describe what you want under \"What do you feel like eating?\" and/or add pantry items, then tap the forward arrow to generate recipes. On Create Recipes, answer each question and tap Next until recipes are generated. Tap a recipe in the list to see details and instructions.'**
  String get tutorialCreateRecipesBody;

  /// No description provided for @tutorialPantryTitle.
  ///
  /// In en, this message translates to:
  /// **'Pantry'**
  String get tutorialPantryTitle;

  /// No description provided for @tutorialPantryBody.
  ///
  /// In en, this message translates to:
  /// **'Under Cuisines you usually cook, pick cuisines so suggestions match your cooking. Tap Add pantry items to search staples, pick suggested chips, or add a custom item. Selected items appear as green pills; tap a pill to remove it. The info icon explains how staples help.'**
  String get tutorialPantryBody;

  /// No description provided for @tutorialImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import recipes'**
  String get tutorialImportTitle;

  /// No description provided for @tutorialImportBody.
  ///
  /// In en, this message translates to:
  /// **'Open the Import tab to add recipes you already have elsewhere. Import from links pastes a URL from the web or social and extracts the recipe fields. Paste recipes accepts full recipe text or a social caption. Scan recipes uses your camera to read a cookbook page or recipe card (on-device OCR on phones). Review the result, then save it to your collection.'**
  String get tutorialImportBody;

  /// No description provided for @tutorialFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved and favorites'**
  String get tutorialFavoritesTitle;

  /// No description provided for @tutorialFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Use the bookmark to save a recipe to your list. Use the heart to favorite it publicly and help it trend. Open the Saved tab for your private list. Sign up to sync to your account.'**
  String get tutorialFavoritesBody;

  /// No description provided for @appMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'App menu'**
  String get appMenuTooltip;

  /// No description provided for @showMeAround.
  ///
  /// In en, this message translates to:
  /// **'Show me around'**
  String get showMeAround;

  /// No description provided for @showMeInApp.
  ///
  /// In en, this message translates to:
  /// **'Show me in the app'**
  String get showMeInApp;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @coachStepNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Five tabs to cook and shop'**
  String get coachStepNavTitle;

  /// No description provided for @coachStepNavBody.
  ///
  /// In en, this message translates to:
  /// **'Use Home for quick ideas and pantry, Create Recipes for the full questionnaire, Grocery for your list, Import to add recipes from elsewhere, and Saved for your private recipe list.'**
  String get coachStepNavBody;

  /// No description provided for @coachStepGetRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Get recipes'**
  String get coachStepGetRecipesTitle;

  /// No description provided for @coachStepGetRecipesBody.
  ///
  /// In en, this message translates to:
  /// **'Describe what you want (optional), add pantry items if you like, then tap the forward arrow to generate recipes.'**
  String get coachStepGetRecipesBody;

  /// No description provided for @coachStepAddPantryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pantry'**
  String get coachStepAddPantryTitle;

  /// No description provided for @coachStepAddPantryBody.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients so suggestions match what you have. You can also tap suggestion chips below.'**
  String get coachStepAddPantryBody;

  /// No description provided for @coachStepFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved recipes'**
  String get coachStepFavoritesTitle;

  /// No description provided for @coachStepFavoritesBody.
  ///
  /// In en, this message translates to:
  /// **'Recipes you bookmark (save) appear here. Sign up from guest mode to sync to your account.'**
  String get coachStepFavoritesBody;

  /// No description provided for @coachStepImportLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Import from links'**
  String get coachStepImportLinksTitle;

  /// No description provided for @coachStepImportLinksBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a URL from the web or social — we\'ll pull out the recipe fields for you.'**
  String get coachStepImportLinksBody;

  /// No description provided for @coachStepImportPasteTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste recipes'**
  String get coachStepImportPasteTitle;

  /// No description provided for @coachStepImportPasteBody.
  ///
  /// In en, this message translates to:
  /// **'Have the text already? Drop the full recipe or caption here and we\'ll structure it.'**
  String get coachStepImportPasteBody;

  /// No description provided for @coachStepImportScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan recipes'**
  String get coachStepImportScanTitle;

  /// No description provided for @coachStepImportScanBody.
  ///
  /// In en, this message translates to:
  /// **'Photograph a cookbook page or recipe card. On your phone we read the text with on-device OCR.'**
  String get coachStepImportScanBody;

  /// No description provided for @groceryListTitle.
  ///
  /// In en, this message translates to:
  /// **'Grocery list'**
  String get groceryListTitle;

  /// No description provided for @groceryListDrawer.
  ///
  /// In en, this message translates to:
  /// **'Grocery list'**
  String get groceryListDrawer;

  /// No description provided for @groceryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Items you add from a recipe or with + will show up here. Open a recipe and choose what you still need to buy.'**
  String get groceryEmptyHint;

  /// No description provided for @groceryAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get groceryAddItem;

  /// No description provided for @groceryEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get groceryEditItem;

  /// No description provided for @groceryFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get groceryFieldName;

  /// No description provided for @groceryNameSearchHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Garlic'**
  String get groceryNameSearchHint;

  /// No description provided for @groceryGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other items'**
  String get groceryGroupOther;

  /// No description provided for @groceryGroupUnnamedRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get groceryGroupUnnamedRecipe;

  /// No description provided for @groceryViewAllIngredients.
  ///
  /// In en, this message translates to:
  /// **'All ingredients'**
  String get groceryViewAllIngredients;

  /// No description provided for @groceryViewPerRecipe.
  ///
  /// In en, this message translates to:
  /// **'Per recipe'**
  String get groceryViewPerRecipe;

  /// No description provided for @groceryIngredientsForRecipe.
  ///
  /// In en, this message translates to:
  /// **'Ingredients needed for {recipeTitle}'**
  String groceryIngredientsForRecipe(String recipeTitle);

  /// No description provided for @groceryFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get groceryFieldQuantity;

  /// No description provided for @groceryFieldUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get groceryFieldUnit;

  /// No description provided for @groceryFieldQuantityOptional.
  ///
  /// In en, this message translates to:
  /// **'Quantity (optional)'**
  String get groceryFieldQuantityOptional;

  /// No description provided for @groceryFieldUnitOptional.
  ///
  /// In en, this message translates to:
  /// **'Unit (optional)'**
  String get groceryFieldUnitOptional;

  /// No description provided for @groceryFieldNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get groceryFieldNoteOptional;

  /// No description provided for @groceryShareList.
  ///
  /// In en, this message translates to:
  /// **'Share list'**
  String get groceryShareList;

  /// No description provided for @groceryCopyList.
  ///
  /// In en, this message translates to:
  /// **'Copy list'**
  String get groceryCopyList;

  /// No description provided for @groceryShareStillNeed.
  ///
  /// In en, this message translates to:
  /// **'Share items still needed'**
  String get groceryShareStillNeed;

  /// No description provided for @groceryCopyStillNeed.
  ///
  /// In en, this message translates to:
  /// **'Copy items still needed'**
  String get groceryCopyStillNeed;

  /// No description provided for @groceryShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Sous Chef — Grocery list'**
  String get groceryShareSubject;

  /// No description provided for @groceryCopied.
  ///
  /// In en, this message translates to:
  /// **'List copied to clipboard'**
  String get groceryCopied;

  /// No description provided for @groceryNothingLeftToBuy.
  ///
  /// In en, this message translates to:
  /// **'No unchecked items left to share'**
  String get groceryNothingLeftToBuy;

  /// No description provided for @groceryClearChecked.
  ///
  /// In en, this message translates to:
  /// **'Clear checked'**
  String get groceryClearChecked;

  /// No description provided for @groceryRemovedChecked.
  ///
  /// In en, this message translates to:
  /// **'Removed checked items'**
  String get groceryRemovedChecked;

  /// No description provided for @recipeAddedToGroceryList.
  ///
  /// In en, this message translates to:
  /// **'Added to grocery list'**
  String get recipeAddedToGroceryList;

  /// No description provided for @cookFlowAddUncheckedToGrocery.
  ///
  /// In en, this message translates to:
  /// **'Add still needed to grocery list'**
  String get cookFlowAddUncheckedToGrocery;

  /// No description provided for @groceryPantryScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan pantry'**
  String get groceryPantryScanTitle;

  /// No description provided for @groceryPantryScanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scan pantry or fridge'**
  String get groceryPantryScanTooltip;

  /// No description provided for @groceryPantryScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a clear photo. We will suggest items—tap ✓ to add to your pantry or ℹ to edit or dismiss.'**
  String get groceryPantryScanSubtitle;

  /// No description provided for @groceryPantryScanSubtitleOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Take a clear photo. On your phone we analyze it on-device—nothing is uploaded. Tap ✓ to add to your pantry.'**
  String get groceryPantryScanSubtitleOnDevice;

  /// No description provided for @groceryPantryScanTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get groceryPantryScanTakePhoto;

  /// No description provided for @groceryPantryScanChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get groceryPantryScanChoosePhoto;

  /// No description provided for @groceryPantryScanWorking.
  ///
  /// In en, this message translates to:
  /// **'Analyzing photo…'**
  String get groceryPantryScanWorking;

  /// No description provided for @groceryPantryScanWorkingOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Analyzing photo on your device…'**
  String get groceryPantryScanWorkingOnDevice;

  /// No description provided for @groceryPantryScanReviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Review detected items'**
  String get groceryPantryScanReviewHeading;

  /// No description provided for @groceryPantryScanLooksLike.
  ///
  /// In en, this message translates to:
  /// **'Looks like'**
  String get groceryPantryScanLooksLike;

  /// No description provided for @groceryPantryScanOtherPossibilities.
  ///
  /// In en, this message translates to:
  /// **'Other possibilities'**
  String get groceryPantryScanOtherPossibilities;

  /// No description provided for @groceryPantryScanScanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get groceryPantryScanScanAgain;

  /// No description provided for @groceryPantryScanScanFromPhoto.
  ///
  /// In en, this message translates to:
  /// **'Scan from photo'**
  String get groceryPantryScanScanFromPhoto;

  /// No description provided for @groceryPantryScanAddToPantry.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get groceryPantryScanAddToPantry;

  /// No description provided for @groceryPantryScanEditItem.
  ///
  /// In en, this message translates to:
  /// **'Edit item name'**
  String get groceryPantryScanEditItem;

  /// No description provided for @groceryPantryScanDismissItem.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get groceryPantryScanDismissItem;

  /// No description provided for @groceryPantryScanAcceptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get groceryPantryScanAcceptTooltip;

  /// No description provided for @groceryPantryScanEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit or dismiss'**
  String get groceryPantryScanEditTooltip;

  /// No description provided for @groceryPantryScanConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get groceryPantryScanConfidence;

  /// No description provided for @groceryPantryScanRemoveRow.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groceryPantryScanRemoveRow;

  /// No description provided for @groceryPantryScanAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add to pantry'**
  String get groceryPantryScanAddSelected;

  /// No description provided for @groceryPantryScanSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to scan your pantry or refrigerator.'**
  String get groceryPantryScanSignInRequired;

  /// No description provided for @groceryPantryScanNoItemsDetected.
  ///
  /// In en, this message translates to:
  /// **'No ingredients were detected in that photo. Try better light, a wider shot, or add items manually.'**
  String get groceryPantryScanNoItemsDetected;

  /// No description provided for @groceryPantryScanSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Pantry scan'**
  String get groceryPantryScanSourceLabel;

  /// No description provided for @groceryPantryScanAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 item to your pantry} other{Added {count} items to your pantry}}'**
  String groceryPantryScanAdded(int count);

  /// No description provided for @groceryPantryScanAddedOne.
  ///
  /// In en, this message translates to:
  /// **'Added to your pantry'**
  String get groceryPantryScanAddedOne;

  /// No description provided for @importRecipeTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importRecipeTabTitle;

  /// No description provided for @importHubTileLinks.
  ///
  /// In en, this message translates to:
  /// **'Import from links'**
  String get importHubTileLinks;

  /// No description provided for @importHubTilePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste recipes'**
  String get importHubTilePaste;

  /// No description provided for @importHubTileScan.
  ///
  /// In en, this message translates to:
  /// **'Scan recipes'**
  String get importHubTileScan;

  /// No description provided for @importRecipeSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to import recipes from links, text, or photos.'**
  String get importRecipeSignInRequired;

  /// No description provided for @importRecipeFromLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Paste any Web / Social Media link'**
  String get importRecipeFromLinkHint;

  /// No description provided for @importRecipePasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste caption or recipe…'**
  String get importRecipePasteHint;

  /// No description provided for @importRecipeExtract.
  ///
  /// In en, this message translates to:
  /// **'Extract'**
  String get importRecipeExtract;

  /// No description provided for @importRecipeBusy.
  ///
  /// In en, this message translates to:
  /// **'Reading recipe…'**
  String get importRecipeBusy;

  /// No description provided for @importRecipeNeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Paste a link first'**
  String get importRecipeNeedUrl;

  /// No description provided for @importRecipeNeedMoreText.
  ///
  /// In en, this message translates to:
  /// **'Paste a bit more text'**
  String get importRecipeNeedMoreText;

  /// No description provided for @importRecipeOcrEmpty.
  ///
  /// In en, this message translates to:
  /// **'No readable text in that photo. Try brighter light, closer crop, or paste the recipe.'**
  String get importRecipeOcrEmpty;

  /// No description provided for @importRecipeWebScanUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Photo import uses on-device OCR in the iOS/Android app. Paste recipe text instead.'**
  String get importRecipeWebScanUnsupported;

  /// No description provided for @savedListSegmentCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get savedListSegmentCreated;

  /// No description provided for @savedListSegmentImported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get savedListSegmentImported;

  /// No description provided for @savedListEmptyCreated.
  ///
  /// In en, this message translates to:
  /// **'No created recipes here yet.'**
  String get savedListEmptyCreated;

  /// No description provided for @savedListEmptyImported.
  ///
  /// In en, this message translates to:
  /// **'No imported recipes here yet.'**
  String get savedListEmptyImported;

  /// No description provided for @howAreYouFeelingToday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howAreYouFeelingToday;

  /// No description provided for @moodHappyExcited.
  ///
  /// In en, this message translates to:
  /// **'Happy/Excited'**
  String get moodHappyExcited;

  /// No description provided for @moodSadTired.
  ///
  /// In en, this message translates to:
  /// **'Sad/Tired'**
  String get moodSadTired;

  /// No description provided for @moodNotHungry.
  ///
  /// In en, this message translates to:
  /// **'Not Hungry'**
  String get moodNotHungry;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @moodFeelingLucky.
  ///
  /// In en, this message translates to:
  /// **'I am feeling lucky! (Suggest any recipe)'**
  String get moodFeelingLucky;

  /// No description provided for @moodAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get moodAngry;

  /// No description provided for @moodConfused.
  ///
  /// In en, this message translates to:
  /// **'Confused'**
  String get moodConfused;

  /// No description provided for @doYouHaveDietaryRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Do you have any Dietary Restrictions?'**
  String get doYouHaveDietaryRestrictions;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietPescitarian.
  ///
  /// In en, this message translates to:
  /// **'Pescitarian'**
  String get dietPescitarian;

  /// No description provided for @dietNonVegetarianWithoutRedMeat.
  ///
  /// In en, this message translates to:
  /// **'Non Vegetarian Without Red Meat'**
  String get dietNonVegetarianWithoutRedMeat;

  /// No description provided for @dietNonVegetarianWithRedMeat.
  ///
  /// In en, this message translates to:
  /// **'Non Vegetarian with no restrictions'**
  String get dietNonVegetarianWithRedMeat;

  /// No description provided for @dietNutFree.
  ///
  /// In en, this message translates to:
  /// **'No Nuts in my food.'**
  String get dietNutFree;

  /// No description provided for @dietPaleo.
  ///
  /// In en, this message translates to:
  /// **'Paleo'**
  String get dietPaleo;

  /// No description provided for @dietKeto.
  ///
  /// In en, this message translates to:
  /// **'Keto'**
  String get dietKeto;

  /// No description provided for @dietGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten Free'**
  String get dietGlutenFree;

  /// No description provided for @dietNoRestrictions.
  ///
  /// In en, this message translates to:
  /// **'No Restrictions'**
  String get dietNoRestrictions;

  /// No description provided for @dietHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @dietKosher.
  ///
  /// In en, this message translates to:
  /// **'Kosher'**
  String get dietKosher;

  /// No description provided for @whatCuisineDoYouFeelLike.
  ///
  /// In en, this message translates to:
  /// **'What Cuisine do you feel like eating today?'**
  String get whatCuisineDoYouFeelLike;

  /// No description provided for @cuisineIndian.
  ///
  /// In en, this message translates to:
  /// **'Indian'**
  String get cuisineIndian;

  /// No description provided for @cuisineMexican.
  ///
  /// In en, this message translates to:
  /// **'Mexican'**
  String get cuisineMexican;

  /// No description provided for @cuisineChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get cuisineChinese;

  /// No description provided for @cuisineThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get cuisineThai;

  /// No description provided for @cuisineKorean.
  ///
  /// In en, this message translates to:
  /// **'Korean'**
  String get cuisineKorean;

  /// No description provided for @cuisineItalian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get cuisineItalian;

  /// No description provided for @cuisineAmerican.
  ///
  /// In en, this message translates to:
  /// **'American'**
  String get cuisineAmerican;

  /// No description provided for @cuisineSurpriseMe.
  ///
  /// In en, this message translates to:
  /// **'Surprise Me with anything!'**
  String get cuisineSurpriseMe;

  /// No description provided for @cuisinePopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get cuisinePopular;

  /// No description provided for @howMuchTimeCooking.
  ///
  /// In en, this message translates to:
  /// **'How much time do you like to spend on Cooking?'**
  String get howMuchTimeCooking;

  /// No description provided for @cookingUnder10Min.
  ///
  /// In en, this message translates to:
  /// **'< 10 Minutes'**
  String get cookingUnder10Min;

  /// No description provided for @cookingTenTo30Min.
  ///
  /// In en, this message translates to:
  /// **'10 – 30 Minutes'**
  String get cookingTenTo30Min;

  /// No description provided for @cookingThirtyTo60Min.
  ///
  /// In en, this message translates to:
  /// **'30 – 60 Minutes'**
  String get cookingThirtyTo60Min;

  /// No description provided for @cookingOver60Min.
  ///
  /// In en, this message translates to:
  /// **'> 60 Minutes'**
  String get cookingOver60Min;

  /// No description provided for @cookingNotParticular.
  ///
  /// In en, this message translates to:
  /// **'Not Particular'**
  String get cookingNotParticular;

  /// No description provided for @allergenMilkDairy.
  ///
  /// In en, this message translates to:
  /// **'Milk / dairy'**
  String get allergenMilkDairy;

  /// No description provided for @allergenEggs.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get allergenEggs;

  /// No description provided for @allergenFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get allergenFish;

  /// No description provided for @allergenShellfish.
  ///
  /// In en, this message translates to:
  /// **'Shellfish'**
  String get allergenShellfish;

  /// No description provided for @allergenPeanuts.
  ///
  /// In en, this message translates to:
  /// **'Peanuts'**
  String get allergenPeanuts;

  /// No description provided for @allergenTreeNuts.
  ///
  /// In en, this message translates to:
  /// **'Tree nuts'**
  String get allergenTreeNuts;

  /// No description provided for @allergenWheatGluten.
  ///
  /// In en, this message translates to:
  /// **'Wheat / gluten'**
  String get allergenWheatGluten;

  /// No description provided for @allergenSoy.
  ///
  /// In en, this message translates to:
  /// **'Soy'**
  String get allergenSoy;

  /// No description provided for @allergenSesame.
  ///
  /// In en, this message translates to:
  /// **'Sesame'**
  String get allergenSesame;

  /// No description provided for @allergenMustard.
  ///
  /// In en, this message translates to:
  /// **'Mustard'**
  String get allergenMustard;

  /// No description provided for @allergenSulfites.
  ///
  /// In en, this message translates to:
  /// **'Sulfites'**
  String get allergenSulfites;

  /// No description provided for @medicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Recipes are generated by AI for inspiration only. They are not verified for food allergies or medical diets. Always check ingredients and labels yourself if you have severe allergies or dietary requirements.'**
  String get medicalDisclaimer;

  /// No description provided for @mealPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal planner'**
  String get mealPlanTitle;

  /// No description provided for @mealPlanDrawer.
  ///
  /// In en, this message translates to:
  /// **'Meal planner'**
  String get mealPlanDrawer;

  /// No description provided for @mealPlanHomePrompt.
  ///
  /// In en, this message translates to:
  /// **'Want help planning your meals? Try out our Meal Planner'**
  String get mealPlanHomePrompt;

  /// No description provided for @mealPlanHomeCta.
  ///
  /// In en, this message translates to:
  /// **'Try Meal Planner'**
  String get mealPlanHomeCta;

  /// No description provided for @mealPlanHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan meals from your pantry and budget. We suggest recipes and what to buy.'**
  String get mealPlanHubSubtitle;

  /// No description provided for @mealPlanStartNew.
  ///
  /// In en, this message translates to:
  /// **'Plan my week'**
  String get mealPlanStartNew;

  /// No description provided for @mealPlanResume.
  ///
  /// In en, this message translates to:
  /// **'View last plan'**
  String get mealPlanResume;

  /// No description provided for @mealPlanWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your plan'**
  String get mealPlanWizardTitle;

  /// No description provided for @mealPlanStepDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet goals'**
  String get mealPlanStepDiet;

  /// No description provided for @mealPlanStepCuisines.
  ///
  /// In en, this message translates to:
  /// **'Cuisines to try'**
  String get mealPlanStepCuisines;

  /// No description provided for @mealPlanStepMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals to plan'**
  String get mealPlanStepMeals;

  /// No description provided for @mealPlanStepDays.
  ///
  /// In en, this message translates to:
  /// **'Days to plan'**
  String get mealPlanStepDays;

  /// No description provided for @mealPlanStepPantry.
  ///
  /// In en, this message translates to:
  /// **'Ingredients you have'**
  String get mealPlanStepPantry;

  /// No description provided for @mealPlanStepBudget.
  ///
  /// In en, this message translates to:
  /// **'Weekly grocery budget'**
  String get mealPlanStepBudget;

  /// No description provided for @mealPlanGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate plan'**
  String get mealPlanGenerate;

  /// No description provided for @mealPlanGenerating.
  ///
  /// In en, this message translates to:
  /// **'Planning your meals…'**
  String get mealPlanGenerating;

  /// No description provided for @mealPlanFreeDayLimit.
  ///
  /// In en, this message translates to:
  /// **'Free plans include up to 3 days. Upgrade for a full week.'**
  String get mealPlanFreeDayLimit;

  /// No description provided for @mealPlanPremiumDays.
  ///
  /// In en, this message translates to:
  /// **'Full week (Premium)'**
  String get mealPlanPremiumDays;

  /// No description provided for @mealPlanMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Still need to buy'**
  String get mealPlanMissingTitle;

  /// No description provided for @mealPlanAddToGrocery.
  ///
  /// In en, this message translates to:
  /// **'Add selected to grocery list'**
  String get mealPlanAddToGrocery;

  /// No description provided for @mealPlanCopyList.
  ///
  /// In en, this message translates to:
  /// **'Copy shopping list'**
  String get mealPlanCopyList;

  /// No description provided for @mealPlanShopInstacart.
  ///
  /// In en, this message translates to:
  /// **'Shop with Instacart'**
  String get mealPlanShopInstacart;

  /// No description provided for @mealPlanInstacartTitle.
  ///
  /// In en, this message translates to:
  /// **'Instacart — coming soon'**
  String get mealPlanInstacartTitle;

  /// No description provided for @mealPlanInstacartBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re finishing our Instacart integration. For now, add items to your grocery list or copy the list to shop in your favorite app.'**
  String get mealPlanInstacartBody;

  /// No description provided for @mealPlanBudgetSummary.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get mealPlanBudgetSummary;

  /// No description provided for @mealPlanOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Estimated total is above your weekly budget.'**
  String get mealPlanOverBudget;

  /// No description provided for @mealPlanRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Try another recipe'**
  String get mealPlanRegenerate;

  /// No description provided for @mealPlanViewRecipe.
  ///
  /// In en, this message translates to:
  /// **'View recipe'**
  String get mealPlanViewRecipe;

  /// No description provided for @mealPlanBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealPlanBreakfast;

  /// No description provided for @mealPlanLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealPlanLunch;

  /// No description provided for @mealPlanDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealPlanDinner;

  /// No description provided for @mealPlanMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mealPlanMon;

  /// No description provided for @mealPlanTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get mealPlanTue;

  /// No description provided for @mealPlanWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get mealPlanWed;

  /// No description provided for @mealPlanThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get mealPlanThu;

  /// No description provided for @mealPlanFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get mealPlanFri;

  /// No description provided for @mealPlanSat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get mealPlanSat;

  /// No description provided for @mealPlanSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get mealPlanSun;

  /// No description provided for @createRecipesPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Recipes preferences'**
  String get createRecipesPreferencesTitle;

  /// No description provided for @searchHeadlineBasedOnCustom.
  ///
  /// In en, this message translates to:
  /// **'Based on what you asked for'**
  String get searchHeadlineBasedOnCustom;

  /// No description provided for @searchHeadlineLuckyMode.
  ///
  /// In en, this message translates to:
  /// **'Variety picks (lucky mode)'**
  String get searchHeadlineLuckyMode;

  /// No description provided for @searchHeadlineQuestionnaire.
  ///
  /// In en, this message translates to:
  /// **'Using your questionnaire and pantry choices'**
  String get searchHeadlineQuestionnaire;

  /// No description provided for @searchHeadlineCreateRecipes.
  ///
  /// In en, this message translates to:
  /// **'Using your Create Recipes preferences'**
  String get searchHeadlineCreateRecipes;

  /// No description provided for @searchHeadlineSavedPreferences.
  ///
  /// In en, this message translates to:
  /// **'Using your saved preferences'**
  String get searchHeadlineSavedPreferences;

  /// No description provided for @searchDetailMood.
  ///
  /// In en, this message translates to:
  /// **'Mood: {value}'**
  String searchDetailMood(String value);

  /// No description provided for @searchDetailDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet: {value}'**
  String searchDetailDiet(String value);

  /// No description provided for @searchDetailCuisine.
  ///
  /// In en, this message translates to:
  /// **'Cuisine: {value}'**
  String searchDetailCuisine(String value);

  /// No description provided for @searchDetailPreferredCuisines.
  ///
  /// In en, this message translates to:
  /// **'Preferred cuisines: {value}'**
  String searchDetailPreferredCuisines(String value);

  /// No description provided for @searchDetailTime.
  ///
  /// In en, this message translates to:
  /// **'Time: {value}'**
  String searchDetailTime(String value);

  /// No description provided for @searchDetailCookingProficiency.
  ///
  /// In en, this message translates to:
  /// **'Cooking proficiency: {value}'**
  String searchDetailCookingProficiency(String value);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @onboardingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepLabel(int current, int total);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet your Sous Chef'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes built around what you eat and what you have.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomeCta.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize'**
  String get onboardingWelcomeCta;

  /// No description provided for @onboardingDietTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you usually eat?'**
  String get onboardingDietTitle;

  /// No description provided for @onboardingDietSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick all that apply. We\'ll tailor every recipe.'**
  String get onboardingDietSubtitle;

  /// No description provided for @onboardingAllergiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Anything we should avoid?'**
  String get onboardingAllergiesTitle;

  /// No description provided for @onboardingAllergiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll steer clear of these ingredients when we can.'**
  String get onboardingAllergiesSubtitle;

  /// No description provided for @onboardingAllergiesNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get onboardingAllergiesNone;

  /// No description provided for @onboardingAllergiesAddNotes.
  ///
  /// In en, this message translates to:
  /// **'Add notes (optional)'**
  String get onboardingAllergiesAddNotes;

  /// No description provided for @onboardingCuisinesTitle.
  ///
  /// In en, this message translates to:
  /// **'What flavors do you love?'**
  String get onboardingCuisinesTitle;

  /// No description provided for @onboardingCuisinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose up to three — we\'ll prioritize these cuisines.'**
  String get onboardingCuisinesSubtitle;

  /// No description provided for @onboardingCuisinesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} selected'**
  String onboardingCuisinesSelectedCount(int count, int max);

  /// No description provided for @onboardingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your kitchen profile'**
  String get onboardingSummaryTitle;

  /// No description provided for @onboardingSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what Sous Chef will remember about you.'**
  String get onboardingSummarySubtitle;

  /// No description provided for @onboardingSummaryDietLine.
  ///
  /// In en, this message translates to:
  /// **'Diet: {value}'**
  String onboardingSummaryDietLine(String value);

  /// No description provided for @onboardingSummaryAllergiesLine.
  ///
  /// In en, this message translates to:
  /// **'Avoid: {value}'**
  String onboardingSummaryAllergiesLine(String value);

  /// No description provided for @onboardingSummaryCuisinesLine.
  ///
  /// In en, this message translates to:
  /// **'Loves: {value}'**
  String onboardingSummaryCuisinesLine(String value);

  /// No description provided for @onboardingSummaryNoAllergens.
  ///
  /// In en, this message translates to:
  /// **'No allergens selected'**
  String get onboardingSummaryNoAllergens;

  /// No description provided for @onboardingSummaryPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tonight Sous Chef might suggest…'**
  String get onboardingSummaryPreviewHint;

  /// No description provided for @onboardingSummaryPreviewPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'A personalized recipe just for you'**
  String get onboardingSummaryPreviewPlaceholder;

  /// No description provided for @onboardingPaywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to cook?'**
  String get onboardingPaywallTitle;

  /// No description provided for @onboardingPaywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Premium unlocks unlimited recipes, pantry scan, and full meal planning.'**
  String get onboardingPaywallSubtitle;

  /// No description provided for @onboardingPaywallBenefitUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI recipe generations'**
  String get onboardingPaywallBenefitUnlimited;

  /// No description provided for @onboardingPaywallBenefitNoAds.
  ///
  /// In en, this message translates to:
  /// **'Pantry scan from photos'**
  String get onboardingPaywallBenefitNoAds;

  /// No description provided for @onboardingPaywallBenefitMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Full-week meal planner'**
  String get onboardingPaywallBenefitMealPlan;

  /// No description provided for @onboardingPaywallSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Start Premium — {price}/mo'**
  String onboardingPaywallSubscribe(String price);

  /// No description provided for @onboardingPaywallSkip.
  ///
  /// In en, this message translates to:
  /// **'Continue with free plan'**
  String get onboardingPaywallSkip;

  /// No description provided for @onboardingPaywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get onboardingPaywallRestore;

  /// No description provided for @onboardingFirstPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the search bar to ask for your first recipe'**
  String get onboardingFirstPromptHint;

  /// No description provided for @freeTierQuotaMessage.
  ///
  /// In en, this message translates to:
  /// **'Free plan includes up to 3 recipe generations per day. Upgrade for unlimited recipes.'**
  String get freeTierQuotaMessage;

  /// No description provided for @freeTierImportQuotaMessage.
  ///
  /// In en, this message translates to:
  /// **'Free plan includes 1 recipe import per day. Upgrade for unlimited imports.'**
  String get freeTierImportQuotaMessage;

  /// No description provided for @dailyCreditsUsed.
  ///
  /// In en, this message translates to:
  /// **'{used}/{total} Credits used'**
  String dailyCreditsUsed(int used, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
