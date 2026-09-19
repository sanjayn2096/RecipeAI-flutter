/// Holds a share-sheet import payload until splash/auth finishes.
class PendingSharedImport {
  PendingSharedImport._();

  static PendingSharedImportPayload? _payload;

  static void set(PendingSharedImportPayload? payload) {
    _payload = payload;
  }

  static PendingSharedImportPayload? peek() => _payload;

  static PendingSharedImportPayload? take() {
    final p = _payload;
    _payload = null;
    return p;
  }

  static void clear() {
    _payload = null;
  }
}

class PendingSharedImportPayload {
  const PendingSharedImportPayload({
    required this.mode,
    this.url,
    this.plainText,
  });

  /// `url` or `text` — matches [RecipeViewModel.importRecipe].
  final String mode;
  final String? url;
  final String? plainText;
}
