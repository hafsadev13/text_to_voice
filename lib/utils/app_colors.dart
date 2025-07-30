import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0xFFA855F7);
  static const Color secondary = Color(0xFF6366F1);
  static const Color backgroundLight = Color(0xFFE5E7EB);
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  // Grey colors
  static const Color grey = Colors.grey;

  // Red colors (with MaterialColor for shades)
  static const MaterialColor red = MaterialColor(
    0xFFE53935,
    <int, Color>{
      50: Color(0xFFFFEBEE),
      100: Color(0xFFFFCDD2),
      200: Color(0xFFEF9A9A),
      300: Color(0xFFE57373),
      400: Color(0xFFEF5350),
      500: Color(0xFFF44336),
      600: Color(0xFFE53935),
      700: Color(0xFFD32F2F),
      800: Color(0xFFC62828),
      900: Color(0xFFB71C1C),
    },
  );

  // Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
  );

  static const Gradient secondaryGradient = LinearGradient(
    colors: [secondary, primary],
  );
}