/// Holds a deep-link path (e.g. `/r/{recipeId}`) until splash/auth finishes.
class PendingDeepLink {
  PendingDeepLink._();

  static String? _path;

  static void set(String? path) {
    final p = path?.trim();
    _path = (p == null || p.isEmpty) ? null : p;
  }

  static String? peek() => _path;

  static String? take() {
    final p = _path;
    _path = null;
    return p;
  }

  static void clear() {
    _path = null;
  }
}
