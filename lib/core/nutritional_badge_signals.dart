import '../data/models/nutritional_value.dart';

/// Parses a macro string such as `"25 g"` or `"~30g protein"` to grams; returns null if unusable.
double? parseMacroGrams(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty || s == 'n/a' || s == 'na' || s == '—') return null;
  final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(s);
  if (m == null) return null;
  return double.tryParse(m.group(1)!);
}

/// High-level macro cues derived from per-serving strings (when numeric).
///
/// Thresholds favor showing badges only when the numbers are reasonably clear.
class MacroBadgeSignals {
  MacroBadgeSignals({required this.proteinRich, required this.carbRich});

  final bool proteinRich;
  final bool carbRich;

  factory MacroBadgeSignals.fromNutritional(NutritionalValue n) {
    final p = parseMacroGrams(n.protein);
    final c = parseMacroGrams(n.carbs);

    if (p == null && c == null) {
      return MacroBadgeSignals(proteinRich: false, carbRich: false);
    }

    bool protein = false;
    bool carb = false;

    if (p != null && c != null) {
      if (p >= 22 && p >= c * 0.85) {
        protein = true;
      }
      if (c >= 38 && c >= p * 1.15) {
        carb = true;
      }
    } else if (p != null) {
      protein = p >= 22;
    } else if (c != null) {
      carb = c >= 38;
    }

    return MacroBadgeSignals(proteinRich: protein, carbRich: carb);
  }
}
