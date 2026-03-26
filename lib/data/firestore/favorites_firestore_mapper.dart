import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/recipe.dart';

/// Maps Firestore favorites subcollection snapshots to [Recipe] list.
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

  static List<Recipe> recipesFromQuerySnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final out = <Recipe>[];
    for (final doc in snapshot.docs) {
      final r = recipeFromDocData(doc.data());
      if (r != null) out.add(r);
    }
    return out;
  }
}
