import 'pending_shared_import.dart';

final _urlInText = RegExp(
  r'https?://[^\s<>"{}|\\^`\[\]]+',
  caseSensitive: false,
);

/// Prefer Instagram / short-link hosts when multiple URLs appear in shared text.
Uri? _preferredSharedUrl(String text) {
  final matches = _urlInText.allMatches(text).toList();
  if (matches.isEmpty) return null;

  Uri? first;
  for (final m in matches) {
    final raw = m.group(0)!.replaceAll(RegExp(r'[.,;:!?)]+$'), '');
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) continue;
    first ??= uri;
    final host = uri.host.toLowerCase();
    if (host == 'instagram.com' ||
        host.endsWith('.instagram.com') ||
        host == 'instagr.am' ||
        host.endsWith('.instagr.am')) {
      return uri;
    }
  }
  return first;
}

/// Turns share-sheet text into an import payload, or null if nothing usable.
PendingSharedImportPayload? parseSharedImportContent(String? content) {
  final text = (content ?? '').trim();
  if (text.isEmpty) return null;

  final url = _preferredSharedUrl(text);
  if (url != null) {
    return PendingSharedImportPayload(mode: 'url', url: url.toString());
  }
  if (text.length >= 10) {
    return PendingSharedImportPayload(mode: 'text', plainText: text);
  }
  return null;
}
