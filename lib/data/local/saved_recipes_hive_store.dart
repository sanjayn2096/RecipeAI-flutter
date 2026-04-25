import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../models/recipe.dart';

/// Persists GET fetch-saved / fetch-favorites JSON (`userId` + `recipes`) locally.
class SavedRecipesHiveStore {
  SavedRecipesHiveStore(this._box);

  final Box<String> _box;

  static const String _payloadKey = 'payload';

  /// Null: no cache or wrong user / corrupt. Empty list: cached "no saved recipes".
  List<Recipe>? readForUserSync(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return null;
    final raw = _box.get(_payloadKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if ((map['userId'] as String?) != currentUserId) return null;
      final list = map['recipes'] as List<dynamic>? ?? [];
      return list
          .map((e) => Recipe.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String userId, List<Recipe> recipes) async {
    if (userId.isEmpty) return;
    final jsonStr = jsonEncode({
      'userId': userId,
      'recipes': recipes.map((r) => r.toJson()).toList(),
    });
    await _box.put(_payloadKey, jsonStr);
  }

  Future<void> clear() async {
    await _box.delete(_payloadKey);
  }

  static Future<Box<String>> openBox() {
    return Hive.openBox<String>(AppConstants.hiveSavedRecipesBox);
  }
}
