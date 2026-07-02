import 'dart:math' show min;

import 'package:flutter/foundation.dart';

import 'recipe_image_cache.dart';

/// Downloads hero image URLs into [RecipeImageCacheManager] before widgets mount.
Future<void> warmRecipeHeroUrls(
  Iterable<String> urls, {
  int maxConcurrent = 2,
}) async {
  final unique = urls
      .map((u) => u.trim())
      .where(
        (u) =>
            u.startsWith('http://') ||
            u.startsWith('https://'),
      )
      .toSet()
      .toList();
  if (unique.isEmpty) return;

  final workers = min(maxConcurrent, unique.length).clamp(1, unique.length);
  final pending = List<String>.from(unique);

  Future<void> worker() async {
    while (pending.isNotEmpty) {
      final url = pending.removeAt(0);
      try {
        await RecipeImageCacheManager.instance.downloadFile(url);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[RecipeImagePrefetch] failed $url: $e');
          debugPrint(st.toString());
        }
      }
    }
  }

  await Future.wait(List.generate(workers, (_) => worker()));
}
