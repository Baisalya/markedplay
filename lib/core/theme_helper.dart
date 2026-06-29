import 'package:flutter/material.dart';
import 'media_enums.dart';

class ThemeHelper {
  // Constants for consistent UI
  static const double radiusExtraLarge = 35.0;
  static const double radiusLarge = 25.0;
  static const double radiusMedium = 16.0;
  static const double radiusSmall = 12.0;

  static const double paddingLarge = 24.0;
  static const double paddingMedium = 16.0;
  static const double paddingSmall = 8.0;

  static ThemeData materialTheme(
    Brightness brightness,
    AppTheme appTheme, {
    Color? customColor,
  }) {
    final seed = primary(appTheme, customColor: customColor);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background(appTheme, customColor: customColor),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary(appTheme),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor(appTheme, customColor: customColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      sliderTheme: const SliderThemeData(trackHeight: 4),
    );
  }

  // ================= PRIMARY COLOR =================

  static Color primary(AppTheme theme, {Color? customColor}) {
    switch (theme) {
      case AppTheme.neon:
        return Colors.cyanAccent;

      case AppTheme.minimal:
        return Colors.black;

      case AppTheme.cinematic:
        return Colors.redAccent;

      case AppTheme.custom:
        return customColor ?? Colors.blueAccent;
    }
  }

  // ================= BACKGROUND COLOR =================

  static Color background(AppTheme theme, {Color? customColor}) {
    switch (theme) {
      case AppTheme.neon:
        return Colors.black;

      case AppTheme.minimal:
        return Colors.white;

      case AppTheme.cinematic:
        return const Color(0xFF121212);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent).withOpacity(0.08);
    }
  }

  // ================= BACKGROUND GRADIENT =================

  static Gradient backgroundGradient(AppTheme theme, {Color? customColor}) {
    switch (theme) {
      case AppTheme.neon:
        return LinearGradient(
          colors: [
            Colors.deepPurple.shade900,
            Colors.black,
            Colors.cyan.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      case AppTheme.minimal:
        return LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade200,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

      case AppTheme.cinematic:
        return const LinearGradient(
          colors: [
            Color(0xFF1F1C2C),
            Color(0xFF928DAB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

      case AppTheme.custom:
        final base = customColor ?? Colors.blueAccent;

        return LinearGradient(
          colors: [
            base.withOpacity(0.8),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  // ================= CARD COLOR =================

  static Color cardColor(AppTheme theme, {Color? customColor}) {
    switch (theme) {
      case AppTheme.neon:
        return Colors.white.withOpacity(0.05);

      case AppTheme.minimal:
        return Colors.grey.shade100;

      case AppTheme.cinematic:
        return Colors.white.withOpacity(0.07);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent).withOpacity(0.15);
    }
  }

  // ================= BORDER COLOR =================

  static Color borderColor(AppTheme theme, {Color? customColor}) {
    switch (theme) {
      case AppTheme.neon:
        return Colors.cyan.withOpacity(0.4);

      case AppTheme.minimal:
        return Colors.grey.shade300;

      case AppTheme.cinematic:
        return Colors.redAccent.withOpacity(0.4);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent).withOpacity(0.6);
    }
  }

  // ================= TEXT COLOR =================

  static Color textPrimary(AppTheme theme) {
    switch (theme) {
      case AppTheme.neon:
        return Colors.white;

      case AppTheme.minimal:
        return Colors.black;

      case AppTheme.cinematic:
        return Colors.white;

      case AppTheme.custom:
        return Colors.white;
    }
  }

  static Color textSecondary(AppTheme theme) {
    switch (theme) {
      case AppTheme.neon:
        return Colors.white70;

      case AppTheme.minimal:
        return Colors.black54;

      case AppTheme.cinematic:
        return Colors.white70;

      case AppTheme.custom:
        return Colors.white70;
    }
  }

  // ================= APPBAR COLOR =================

  static Color appBarColor(AppTheme theme, {Color? customColor}) {
    return Colors.transparent;
  }
}
