import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextStyle headlineLarge(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.white,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle button(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.white,
    );
  }

  static TextStyle statusTitle(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.grey,
    );
  }

  static TextStyle statusMessage(BuildContext context, Color color) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
}