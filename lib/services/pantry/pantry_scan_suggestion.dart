import '../../data/api/api_service.dart';

/// User-facing pantry scan result — no confidence scores or internal OCR tags.
class PantryScanSuggestion {
  const PantryScanSuggestion({
    required this.primaryName,
    this.quantity = '',
    this.unit = '',
    this.alternates = const [],
  });

  final String primaryName;
  final String quantity;
  final String unit;

  /// Other plausible names the user can pick instead of [primaryName].
  final List<String> alternates;

  /// All selectable names: primary first, then alternates.
  List<String> get allNames => [primaryName, ...alternates];

  String toIngredientLine(String selectedName) {
    final parts = <String>[];
    if (quantity.isNotEmpty) parts.add(quantity);
    if (unit.isNotEmpty) parts.add(unit);
    parts.add(selectedName.trim());
    return parts.join(' ').trim();
  }

  /// Cloud API items → one suggestion each (no alternates).
  static List<PantryScanSuggestion> fromApiItems(List<PantryScanItem> items) {
    return items
        .where((e) => e.name.trim().isNotEmpty)
        .map(
          (e) => PantryScanSuggestion(
            primaryName: e.name.trim(),
            quantity: e.quantity.trim(),
            unit: e.unit.trim(),
          ),
        )
        .toList();
  }
}
