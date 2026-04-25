/// Firestore layout for saved recipes and legacy favorites.
class FirestorePaths {
  FirestorePaths._();

  static const String usersCollection = 'users';

  /// Private "Saved" tab list.
  static const String savedSubcollection = 'saved';

  /// Legacy: before split, the personal list used this name. Still streamed for migration.
  static const String legacyFavoritesSubcollection = 'favorites';

  /// Grocery list items for signed-in users.
  static const String grocerySubcollection = 'groceryItems';
}
