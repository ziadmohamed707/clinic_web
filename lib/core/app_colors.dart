import 'package:flutter/material.dart';

/// App color palette based on PhysioOne logo.
class AppColors {
  AppColors._();

  // Primary (Orange from logo)
  static const Color primary = Color(0xFFD18700); // برتقالي ذهبي دافئ
  static const Color primaryDark = Color(0xFFB06C00);
  static const Color primaryLight = Color(0xFFF4B23A);

  // Secondary (Dark Gray-Blue from text)
  static const Color secondary = Color(0xFF38424B);
  static const Color secondaryDark = Color(0xFF2B333B);
  static const Color secondaryLight = Color(0xFF4F5A63);

  // Background & Neutrals
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Colors.white;
  static const Color black = Color(0xFF1C1C1C);
  static const Color white = Colors.white;

  // Status Colors
  static const Color error = Color(0xFFE53935);

  // MaterialColor for primarySwatch (orange tone)
  static const MaterialColor primarySwatch =
      MaterialColor(0xFFD18700, <int, Color>{
        50: Color(0xFFFFF3E0),
        100: Color(0xFFFFE0B2),
        200: Color(0xFFFFCC80),
        300: Color(0xFFFFB74D),
        400: Color(0xFFFFA726),
        500: Color(0xFFD18700),
        600: Color(0xFFB06C00),
        700: Color(0xFF9A5E00),
        800: Color(0xFF7F4C00),
        900: Color(0xFF5E3800),
      });
}
