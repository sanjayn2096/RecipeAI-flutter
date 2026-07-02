import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_ai/l10n/app_localizations.dart';

void main() {
  test('Spanish locale loads translated strings', () {
    final es = lookupAppLocalizations(const Locale('es'));
    expect(es.next, 'Siguiente');
    expect(es.groceryListTitle, 'Lista de compras');
    expect(es.moodFeelingLucky, contains('suerte'));
  });

  test('English locale loads template strings', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.next, 'Next');
    expect(en.groceryListTitle, 'Grocery list');
  });

  test('supportedLocales includes English and Spanish', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll([const Locale('en'), const Locale('es')]),
    );
  });
}
