import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Google Stitch Design System Tokens - Clinical Precision
  static const stitchPrimary = Color(0xFF006B53);           // #006b53 Teal Emerald
  static const stitchPrimaryContainer = Color(0xFF00A884);  // #00a884
  static const stitchPrimaryFixed = Color(0xFF79F9D0);      // #79f9d0 Active Highlight
  static const stitchSecondary = Color(0xFF0060AC);         // #0060ac Medical Blue
  static const stitchTertiary = Color(0xFF005AC2);          // #005ac2 Accent
  static const stitchWarning = Color(0xFFF59E0B);           // Amber Warning
  static const stitchDanger = Color(0xFFBA1A1A);            // Error Red
  static const stitchSurfaceLight = Color(0xFFF7F9FB);      // Light Background
  static const stitchSurfaceDark = Color(0xFF0F172A);       // Slate 900
  static const stitchCardDark = Color(0xFF1E293B);          // Slate 800
  static const stitchOutlineVariant = Color(0xFFBCCAC2);    // Outline Variant

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: stitchSurfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: stitchPrimaryContainer,
        secondary: stitchSecondary,
        tertiary: stitchTertiary,
        surface: stitchCardDark,
        error: stitchDanger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: stitchCardDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: stitchCardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33BCCAC2)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: stitchSurfaceLight,
      colorScheme: const ColorScheme.light(
        primary: stitchPrimary,
        secondary: stitchSecondary,
        tertiary: stitchTertiary,
        surface: Colors.white,
        error: stitchDanger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.hankenGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF191C1E),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: stitchOutlineVariant),
        ),
      ),
    );
  }
}
