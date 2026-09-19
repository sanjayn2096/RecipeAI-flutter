import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/navigation/shared_import_parser.dart';

void main() {
  test('parses Instagram URL from shared text', () {
    final payload = parseSharedImportContent(
      'Check this out https://www.instagram.com/p/AbCdEf123/ via Instagram',
    );
    expect(payload, isNotNull);
    expect(payload!.mode, 'url');
    expect(payload.url, 'https://www.instagram.com/p/AbCdEf123/');
  });

  test('prefers Instagram URL when multiple URLs present', () {
    final payload = parseSharedImportContent(
      'https://example.com/x https://www.instagram.com/reel/ZZZ/',
    );
    expect(payload!.mode, 'url');
    expect(payload.url, 'https://www.instagram.com/reel/ZZZ/');
  });

  test('falls back to text mode for caption without URL', () {
    final payload = parseSharedImportContent(
      'Garlic Pasta\nIngredients\n2 cups pasta\nInstructions\nBoil water',
    );
    expect(payload!.mode, 'text');
    expect(payload.plainText, contains('Garlic Pasta'));
  });

  test('returns null for empty or tiny text', () {
    expect(parseSharedImportContent(null), isNull);
    expect(parseSharedImportContent('hi'), isNull);
  });
}
