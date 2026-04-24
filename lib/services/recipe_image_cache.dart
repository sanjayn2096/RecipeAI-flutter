import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local cache for generated recipe image URLs (hero + per-step), keyed by [recipeId].
/// Invalidated when the recipe [instructions] text changes (hash mismatch).
class RecipeImageCache {
  RecipeImageCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'recipe_images_v1_';

  static int instructionsHash(String instructions) => instructions.hashCode;

  String _key(String recipeId) => '$_prefix${recipeId.trim()}';

  /// Returns parsed cache if [recipeId] exists and [instructions] hash matches.
  Future<RecipeImageCacheData?> get(String recipeId, String instructions) async {
    final id = recipeId.trim();
    if (id.isEmpty) return null;
    final raw = _prefs.getString(_key(id));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if ((m['h'] as num?)?.toInt() != instructionsHash(instructions)) {
        return null;
      }
      return RecipeImageCacheData.fromJson(m);
    } catch (_) {
      return null;
    }
  }

  /// Writes hero URL and resizes/initializes [steps] to [stepCount] (empty strings).
  Future<void> setHero(
    String recipeId,
    String instructions,
    String heroUrl, {
    required int stepCount,
  }) async {
    final id = recipeId.trim();
    if (id.isEmpty) return;
    final existing = await get(id, instructions);
    final steps = List<String>.filled(
      stepCount,
      '',
      growable: true,
    );
    if (existing != null && existing.stepUrls.length == stepCount) {
      for (var i = 0; i < stepCount; i++) {
        if (existing.stepUrls[i].trim().isNotEmpty) {
          steps[i] = existing.stepUrls[i];
        }
      }
    }
    await _write(id, instructions, heroUrl, steps);
  }

  /// Sets one step URL (index >= 0). Grows the list to [stepCount] if needed.
  Future<void> setStepUrl(
    String recipeId,
    String instructions,
    int index,
    String url, {
    required int stepCount,
  }) async {
    final id = recipeId.trim();
    if (id.isEmpty) return;
    final data = await get(id, instructions);
    final steps = data != null
        ? List<String>.from(data.stepUrls)
        : List<String>.filled(stepCount, '', growable: true);
    while (steps.length < stepCount) {
      steps.add('');
    }
    if (index >= 0 && index < steps.length) {
      steps[index] = url;
    }
    final hero = data?.heroUrl ?? '';
    await _write(id, instructions, hero, steps);
  }

  /// Full replace (e.g. after merge from list).
  Future<void> setAll(
    String recipeId,
    String instructions,
    String heroUrl,
    List<String> stepUrls,
  ) async {
    final id = recipeId.trim();
    if (id.isEmpty) return;
    await _write(id, instructions, heroUrl, List<String>.from(stepUrls));
  }

  Future<void> _write(
    String recipeId,
    String instructions,
    String heroUrl,
    List<String> stepUrls,
  ) async {
    final m = {
      'h': instructionsHash(instructions),
      'hero': heroUrl,
      'steps': stepUrls,
    };
    await _prefs.setString(_key(recipeId), jsonEncode(m));
  }
}

class RecipeImageCacheData {
  RecipeImageCacheData({required this.heroUrl, required this.stepUrls});

  final String heroUrl;
  final List<String> stepUrls;

  factory RecipeImageCacheData.fromJson(Map<String, dynamic> m) {
    final hero = (m['hero'] ?? '').toString();
    final raw = m['steps'];
    final list = <String>[];
    if (raw is List) {
      for (final e in raw) {
        list.add(e.toString());
      }
    }
    return RecipeImageCacheData(heroUrl: hero, stepUrls: list);
  }
}
