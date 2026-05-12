/// Distinguishes AI-generated recipes from imported (URL / paste / OCR) recipes.
enum RecipeOrigin {
  /// Created via in-app generation (Create Recipes / home flow).
  generated,

  /// Imported via the Import tab or equivalent.
  imported;

  /// JSON / Firestore wire string for [save-favorites] and API payloads.
  String get wireValue => switch (this) {
        imported => 'imported',
        generated => 'generated',
      };

  static RecipeOrigin fromWire(dynamic v) {
    if (v == null) return RecipeOrigin.generated;
    final s = v.toString().trim().toLowerCase();
    if (s == 'imported') return RecipeOrigin.imported;
    return RecipeOrigin.generated;
  }
}
