/// Formats a stored name for display: first letter of each word uppercased, the rest lowercased.
/// Hyphen-separated parts (e.g. "jean-paul") are formatted per segment.
String formatPersonNamePart(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  return t.split(RegExp(r'\s+')).map(_formatNameToken).join(' ');
}

String _formatNameToken(String token) {
  if (token.isEmpty) return token;
  return token.split('-').map(_capitalizeSegment).join('-');
}

String _capitalizeSegment(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1).toLowerCase();
}
