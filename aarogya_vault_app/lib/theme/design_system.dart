// lib/theme/design_system.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary teal
  static const Color primary = Color(0xFF005F5F);
  static const Color primaryContainer = Color(0xFF007A7A);
  static const Color onPrimary = Colors.white;
  // Secondary emerald
  static const Color secondary = Color(0xFF006C49);
  static const Color onSecondary = Colors.white;
  // Tertiary red
  static const Color tertiary = Color(0xFFAC0031);
  static const Color onTertiary = Colors.white;

  static const Color surface = Color(0xFFF8F9FF);
  static const Color background = Colors.white;
  static const Color error = Color(0xFFBA1A1A);
  // Add more colors as needed
}

class AppTextStyles {
  static final TextStyle display = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
    color: Colors.black,
  );

  static final TextStyle headlineLg = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: Colors.black,
  );

  static final TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: Colors.black,
  );

  static final TextStyle labelBold = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.6,
    color: Colors.black,
  );

  static final TextStyle dataNumeric = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: -0.18,
    color: Colors.black,
  );
}
