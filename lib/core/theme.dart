import 'package:flutter/material.dart';

const Color _kSeed = Colors.orange;

final ThemeData appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(seedColor: _kSeed, brightness: Brightness.light),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
);

final ThemeData appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(seedColor: _kSeed, brightness: Brightness.dark),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
);
