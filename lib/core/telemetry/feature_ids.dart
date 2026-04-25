/// Stable names for [AppTelemetry.logFeatureInteraction] (low cardinality).
abstract final class FeatureIds {
  static const generateRecipe = 'generate_recipe';
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
}
