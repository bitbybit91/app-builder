import 'package:flutter/material.dart';

/// Centralized theming for CapitalMonero.
///
/// Colors are inspired by the original AgoraDesk/LocalMonero palette:
/// orange Monero accents on a neutral surface so values are easy to read.
class AppTheme {
  AppTheme._();

  static const Color brandOrange = Color(0xFFFF6600);
  static const Color brandOrangeDark = Color(0xFFCC5200);
  static const Color brandAccent = Color(0xFF1B5E20);
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color errorRed = Color(0xFFD32F2F);

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: Brightness.light,
      error: errorRed,
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: Brightness.dark,
      error: errorRed,
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final TextTheme baseText = Typography.material2021().englishLike.apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        color: scheme.surfaceContainerLow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: baseText.labelMedium ?? const TextStyle(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(baseText.labelSmall),
        backgroundColor: scheme.surface,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 0.6),
    );
  }
}
