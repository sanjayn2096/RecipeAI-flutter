/// Heuristic parsing of recipe [ingredients] and [instructions] strings from the API.
///
/// Handles newline lists, bullets, numbered items, and simple single-paragraph fallbacks.
abstract class RecipeParsing {
  RecipeParsing._();

  static List<String> parseIngredients(String raw) {
    final items = _parseLines(raw);
    if (items.isEmpty) return [];
    if (items.length == 1) {
      final single = items.single;
      if (single.contains(',') || single.contains(';')) {
        final split = single
            .split(RegExp(r'[,;]\s*'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (split.length > 1) {
          return _dedupe(split);
        }
      }
    }
    return _dedupe(items);
  }

  static List<String> parseInstructions(String raw) {
    var items = _parseLines(raw);
    if (items.isEmpty) return [];
    if (items.length == 1) {
      final sentences = _splitSentences(items.single);
      if (sentences.length > 1) {
        return _dedupe(sentences);
      }
    }
    return _dedupe(items);
  }

  static List<String> _parseLines(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return [];

    final newlineParts = t
        .split(RegExp(r'\r?\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(_stripBulletOrNumberPrefix)
        .where((s) => s.isNotEmpty)
        .toList();

    if (newlineParts.length > 1) {
      return newlineParts;
    }

    final single = newlineParts.isEmpty ? t : newlineParts.single;
    final numbered = _splitNumberedInSingleLine(single);
    if (numbered.length > 1) {
      return numbered;
    }

    final one = _stripBulletOrNumberPrefix(single).trim();
    return one.isEmpty ? [] : [one];
  }

  /// Split "1. a 2. b" or "1) a 2) b" style single-line lists.
  static List<String> _splitNumberedInSingleLine(String text) {
    final t = text.trim();
    if (t.isEmpty) return [];

    final hasNumberedItems = RegExp(r'\d{1,3}[\.)]\s').hasMatch(t);
    if (!hasNumberedItems) {
      return [_stripBulletOrNumberPrefix(t)];
    }

    final chunks = t
        .split(RegExp(r'\s+(?=\d{1,3}[\.)]\s)'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(_stripBulletOrNumberPrefix)
        .where((s) => s.isNotEmpty)
        .toList();

    return chunks.length <= 1 ? [_stripBulletOrNumberPrefix(t)] : chunks;
  }

  static String _stripBulletOrNumberPrefix(String line) {
    var s = line.trim();
    if (s.isEmpty) return s;

    // Leading bullets: - * • · ▪ ▸
    s = s.replaceFirst(RegExp(r'^[-*•·▪▸]+\s*'), '');
    // Leading "Step N:" / "N -"
    s = s.replaceFirst(RegExp(r'^step\s*\d+\s*[:.)-]*\s*', caseSensitive: false), '');
    // Numbered: 1. 1) 1-
    s = s.replaceFirst(RegExp(r'^\d{1,3}[\.)-]\s*'), '');

    return s.trim();
  }

  static List<String> _splitSentences(String paragraph_) {
    final paragraph = paragraph_.trim();
    if (paragraph.isEmpty) return [];

    final parts = paragraph
        .split(RegExp(r'(?<=[.!?])\s+|(?<=[.!?])$'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (parts.length <= 1 && paragraph.length > 80) {
      // Very long single chunk: split on ";" as a last resort
      final semi = paragraph
          .split(RegExp(r';\s*'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (semi.length > 1) return semi;
    }

    return parts;
  }

  static List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in items) {
      final key = item.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(item);
    }
    return out;
  }
}
