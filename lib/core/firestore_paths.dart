/// Firestore layout for favorites (adjust to match Firebase console).
class FirestorePaths {
  FirestorePaths._();

  static const String usersCollection = 'users';

  /// Subcollection under `users/{userId}/…`. Confirm name in console if needed.
  static const String favoritesSubcollection = 'favorites';
}
