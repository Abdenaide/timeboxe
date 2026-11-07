import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF141A22);
  static const Color surfaceLight = Color(0xFF1E2530);
  static const Color surfaceElevated = Color(0xFF252D38);

  // Primary - Boxing Red
  static const Color primary = Color(0xFFFF3B3B);
  static const Color primaryDark = Color(0xFFE02020);
  static const Color primaryLight = Color(0xFFFF6B6B);

  // Phase Colors
  static const Color roundColor = Color(0xFFFF3B3B);
  static const Color restColor = Color(0xFF00E676);
  static const Color prepColor = Color(0xFFFFB300);
  static const Color warningColor = Color(0xFFFF6D00);
  static const Color finishedColor = Color(0xFF7C4DFF);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF8892A0);
  static const Color textMuted = Color(0xFF5A6270);

  // Utility
  static const Color divider = Color(0xFF2A3240);
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF5252);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF3B3B), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E14), Color(0xFF141A22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient roundGradient = LinearGradient(
    colors: [Color(0xFFFF3B3B), Color(0xFFE02020)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient restGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient prepGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFA000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF6D00), Color(0xFFFF3D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Get color for timer phase
  static Color getPhaseColor(String phase) {
    switch (phase) {
      case 'preparation':
        return prepColor;
      case 'round':
        return roundColor;
      case 'rest':
        return restColor;
      case 'warning':
        return warningColor;
      case 'finished':
        return finishedColor;
      default:
        return primary;
    }
  }

  // Get gradient for timer phase
  static LinearGradient getPhaseGradient(String phase) {
    switch (phase) {
      case 'preparation':
        return prepGradient;
      case 'round':
        return roundGradient;
      case 'rest':
        return restGradient;
      case 'warning':
        return warningGradient;
      default:
        return primaryGradient;
    }
  }
}
