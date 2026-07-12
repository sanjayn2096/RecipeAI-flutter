/// Stable names for [AppTelemetry.logFeatureInteraction] (low cardinality).
abstract final class FeatureIds {
  static const generateRecipe = 'generate_recipe';
  static const generateRecipeFollowUp = 'generate_recipe_follow_up';
  static const toggleFavorite = 'toggle_favorite';
  static const toggleSave = 'toggle_save';
  static const togglePublicFavorite = 'toggle_public_favorite';
  static const fetchFavorites = 'fetch_favorites';
  static const fetchSaved = 'fetch_saved';
  static const removeFavorite = 'remove_favorite';
  static const removeSaved = 'remove_saved';
  static const openTrending = 'open_trending';
  static const guestMode = 'guest_mode';
  static const loginEmail = 'login_email';
  static const signInGoogle = 'sign_in_google';
  static const signUp = 'sign_up';
  static const signOut = 'sign_out';

  static const groceryAddFromRecipe = 'grocery_add_from_recipe';
  static const groceryAddManual = 'grocery_add_manual';
  static const groceryDeleteItem = 'grocery_delete_item';
  static const groceryClearChecked = 'grocery_clear_checked';
  static const groceryMergeGuestToCloud = 'grocery_merge_guest_to_cloud';
  static const groceryShare = 'grocery_share';
  static const groceryCopy = 'grocery_copy';
  static const groceryPantryScanAnalyze = 'grocery_pantry_scan_analyze';
  static const groceryPantryScanConfirmAdd = 'grocery_pantry_scan_confirm_add';
  static const groceryPantryScanAddAllToPantry =
      'grocery_pantry_scan_add_all_to_pantry';
  static const groceryPantryScanGenerateRecipes =
      'grocery_pantry_scan_generate_recipes';

  static const importRecipe = 'import_recipe';
  static const recipeAssistantOpen = 'recipe_assistant_open';
  static const recipeAssistantAsk = 'recipe_assistant_ask';
  static const recipeAssistantVoice = 'recipe_assistant_voice';
  static const recipeAssistantTts = 'recipe_assistant_tts';
  static const recipeAssistantPremiumCta = 'recipe_assistant_premium_cta';

  static const premiumCta = 'premium_cta';
  static const premiumSubscribe = 'premium_subscribe';
  static const premiumRestore = 'premium_restore';
  static const premiumPromoRedeem = 'premium_promo_redeem';
  static const openLatestRecipes = 'open_latest_recipes';

  static const mealPlanOpen = 'meal_plan_open';
  static const mealPlanGenerate = 'meal_plan_generate';
  static const mealPlanRegenerateSlot = 'meal_plan_regenerate_slot';
  static const mealPlanAddToGrocery = 'meal_plan_add_to_grocery';
  static const mealPlanInstacartSoon = 'meal_plan_instacart_soon';
  static const mealPlanCopyList = 'meal_plan_copy_list';
  static const fetchDailyIdeas = 'fetch_daily_ideas';

  static const onboardingComplete = 'onboarding_complete';
  static const onboardingPaywallSkip = 'onboarding_paywall_skip';
  static const onboardingPaywallSubscribe = 'onboarding_paywall_subscribe';
}
