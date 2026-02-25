import 'package:flutter/material.dart';
import 'media_enums.dart';

class ThemeHelper {

  // ================= PRIMARY COLOR =================

  static Color primary(AppTheme theme,
      {Color? customColor}) {
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

  static Color background(AppTheme theme,
      {Color? customColor}) {
    switch (theme) {

      case AppTheme.neon:
        return Colors.black;

      case AppTheme.minimal:
        return Colors.white;

      case AppTheme.cinematic:
        return const Color(0xFF121212);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent)
            .withOpacity(0.08);
    }
  }

  // ================= BACKGROUND GRADIENT =================

  static Gradient backgroundGradient(AppTheme theme,
      {Color? customColor}) {
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

  static Color cardColor(AppTheme theme,
      {Color? customColor}) {
    switch (theme) {

      case AppTheme.neon:
        return Colors.white.withOpacity(0.05);

      case AppTheme.minimal:
        return Colors.grey.shade100;

      case AppTheme.cinematic:
        return Colors.white.withOpacity(0.07);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent)
            .withOpacity(0.15);
    }
  }

  // ================= BORDER COLOR =================

  static Color borderColor(AppTheme theme,
      {Color? customColor}) {
    switch (theme) {

      case AppTheme.neon:
        return Colors.cyan.withOpacity(0.4);

      case AppTheme.minimal:
        return Colors.grey.shade300;

      case AppTheme.cinematic:
        return Colors.redAccent.withOpacity(0.4);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent)
            .withOpacity(0.6);
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

  static Color appBarColor(AppTheme theme,
      {Color? customColor}) {
    switch (theme) {

      case AppTheme.neon:
        return Colors.black;

      case AppTheme.minimal:
        return Colors.white;

      case AppTheme.cinematic:
        return const Color(0xFF1A1A1A);

      case AppTheme.custom:
        return (customColor ?? Colors.blueAccent)
            .withOpacity(0.2);
    }
  }
}