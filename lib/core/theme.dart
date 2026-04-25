import 'package:flutter/material.dart';

/// Brand yellow (filled buttons, menu tile, accents). Same in light and dark.
const Color kSousChefPrimaryYellow = Color(0xFFFFD54F);

/// Light shell / scaffold background (warm cream).
const Color kSousChefLightSurface = Color(0xFFFFFAF0);

/// Softer yellow for nav indicator etc.
const Color kSousChefYellowLight = Color(0xFFFFECB3);

/// Dark scaffold / app chrome (warm near-black).
const Color kSousChefDarkSurface = Color(0xFF25211D);

const Color kSousChefDarkSurfaceContainer = Color(0xFF342F2B);

ColorScheme _lightScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: kSousChefPrimaryYellow,
    brightness: Brightness.light,
  );
  return base.copyWith(
    surface: kSousChefLightSurface,
    onSurface: const Color(0xFF0D0D0D),
    onSurfaceVariant: const Color(0xFF424242),
    primary: kSousChefPrimaryYellow,
    onPrimary: const Color(0xFF000000),
    secondary: kSousChefPrimaryYellow,
    onSecondary: const Color(0xFF000000),
    tertiary: const Color(0xFFFF8F00),
    surfaceContainerLowest: kSousChefLightSurface,
    surfaceContainerLow: const Color(0xFFFFF5E6),
    surfaceContainer: const Color(0xFFFFF0E0),
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: const Color(0xFFF0EBE3),
  );
}

ColorScheme _darkScheme() {
  final base = ColorScheme.fromSeed(
    seedColor: kSousChefPrimaryYellow,
    brightness: Brightness.dark,
  );
  return base.copyWith(
    surface: kSousChefDarkSurface,
    onSurface: const Color(0xFFF7F4F0),
    onSurfaceVariant: const Color(0xFFCFC8C0),
    primary: kSousChefPrimaryYellow,
    onPrimary: const Color(0xFF000000),
    secondary: kSousChefPrimaryYellow,
    onSecondary: const Color(0xFF000000),
    surfaceContainerLowest: kSousChefDarkSurface,
    surfaceContainerLow: const Color(0xFF2C2824),
    surfaceContainer: kSousChefDarkSurfaceContainer,
    surfaceContainerHigh: kSousChefDarkSurfaceContainer,
    surfaceContainerHighest: const Color(0xFF3D3834),
  );
}

NavigationBarThemeData _navigationBarTheme(ColorScheme scheme) {
  return NavigationBarThemeData(
    backgroundColor: scheme.surface,
    indicatorColor: kSousChefYellowLight,
    surfaceTintColor: Colors.transparent,
    height: 72,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(
        size: 24,
        color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
      );
    }),
  );
}

ThemeData _buildAppTheme({
  required ColorScheme colorScheme,
  required Brightness brightness,
}) {
  final isDark = brightness == Brightness.dark;
  final textTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
  ).textTheme.apply(
        displayColor: colorScheme.onSurface,
        bodyColor: colorScheme.onSurface,
      );

  final filledStyle = FilledButton.styleFrom(
    backgroundColor: colorScheme.primary,
    foregroundColor: colorScheme.onPrimary,
    disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
    disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: filledStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.primary, width: 1.4),
        backgroundColor: colorScheme.surface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onPrimary,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: _navigationBarTheme(colorScheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurfaceVariant;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

final ThemeData appLightTheme = _buildAppTheme(
  colorScheme: _lightScheme(),
  brightness: Brightness.light,
);

final ThemeData appDarkTheme = _buildAppTheme(
  colorScheme: _darkScheme(),
  brightness: Brightness.dark,
);
