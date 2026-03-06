import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: Brightness.light),
  appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
);
