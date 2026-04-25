import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

/// Maps Firestore saved / legacy-favorites subcollection snapshots to [Recipe] list.
class FavoritesFirestoreMapper {
  const FavoritesFirestoreMapper._();

  /// Parses one document: flat recipe fields or nested `recipe` map.
  static Recipe? recipeFromDocData(Map<String, dynamic> data) {
    try {
      return Recipe.fromJson(data);
    } catch (_) {
      final nested = data['recipe'];
      if (nested is Map) {
        try {
          return Recipe.fromJson(Map<String, dynamic>.from(nested));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  static Recipe? recipeFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    bool isSaved = true,
  }) {
    final data = doc.data();
    if (data == null) return null;
    final merged = Map<String, dynamic>.from(data);
    merged['recipeId'] = merged['recipeId'] ?? doc.id;
    merged['isSaved'] = isSaved;
    merged['isFavorite'] = isSaved;
    return recipeFromDocData(merged);
  }

  static List<Recipe> recipesFromQuerySnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final out = <Recipe>[];
    for (final doc in snapshot.docs) {
      final r = recipeFromDoc(doc, isSaved: true);
      if (r != null) out.add(r);
    }
    return out;
  }

  /// Merges `saved` and legacy `favorites` by [recipeId]; prefer [saved] on conflict.
  static List<Recipe> mergeSavedAndLegacy(
    QuerySnapshot<Map<String, dynamic>>? saved,
    QuerySnapshot<Map<String, dynamic>>? legacy,
  ) {
    final byId = <String, Recipe>{};
    if (legacy != null) {
      for (final doc in legacy.docs) {
        final r = recipeFromDoc(doc, isSaved: true);
        if (r != null) byId[doc.id] = r;
      }
    }
    if (saved != null) {
      for (final doc in saved.docs) {
        final r = recipeFromDoc(doc, isSaved: true);
        if (r != null) byId[doc.id] = r;
      }
    }
    return byId.values.toList();
  }
}
