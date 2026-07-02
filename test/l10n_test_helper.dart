import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recipe_ai/l10n/app_localizations.dart';

/// Wraps a widget in [MaterialApp] with English localizations for tests.
Widget wrapWithL10n(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: child,
  );
}

/// English [AppLocalizations] for unit tests (no widget tree).
AppLocalizations englishL10n() => lookupAppLocalizations(const Locale('en'));
