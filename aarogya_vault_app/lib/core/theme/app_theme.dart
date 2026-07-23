import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Stitch Design Tokens ────────────────────────────────────────────────────
  static const Color primary            = Color(0xFF005F5F);
  static const Color onPrimary          = Color(0xFFFFFFFF);
  static const Color primaryContainer   = Color(0xFF007A7A);
  static const Color onPrimaryContainer = Color(0xFFACFFFE);
  static const Color primaryFixedDim    = Color(0xFF7AD5D5);

  // ── Legacy Aliases (backward compat for older screens) ──────────────────────
  static const Color primaryTeal = Color(0xFF005F5F); // = primary
  static const Color errorRed    = Color(0xFFBA1A1A); // = error
  static const Color darkBg      = Color(0xFF0B1C30);
  static const Color lightBg     = Color(0xFFF8F9FF); // = surface

  static const Color secondary            = Color(0xFF006C49);
  static const Color onSecondary          = Color(0xFFFFFFFF);
  static const Color secondaryContainer   = Color(0xFF6CF8BB);
  static const Color onSecondaryContainer = Color(0xFF00714D);

  static const Color tertiary            = Color(0xFFAC0031);
  static const Color onTertiary          = Color(0xFFFFFFFF);
  static const Color tertiaryContainer   = Color(0xFFD71142);

  static const Color error              = Color(0xFFBA1A1A);
  static const Color onError            = Color(0xFFFFFFFF);
  static const Color errorContainer     = Color(0xFFFFDAD6);
  static const Color onErrorContainer   = Color(0xFF93000A);

  static const Color surface               = Color(0xFFF8F9FF);
  static const Color onSurface            = Color(0xFF0B1C30);
  static const Color surfaceBright        = Color(0xFFF8F9FF);
  static const Color surfaceDim           = Color(0xFFCBDBF5);
  static const Color surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow     = Color(0xFFEFF4FF);
  static const Color surfaceContainer        = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh    = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceVariant       = Color(0xFFD3E4FE);

  static const Color onSurfaceVariant = Color(0xFF3E4948);
  static const Color outline          = Color(0xFF6E7979);
  static const Color outlineVariant   = Color(0xFFBDC9C8);

  static const Color inverseSurface  = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color inversePrimary  = Color(0xFF7AD5D5);

  // ── Extended Color Aliases ──────────────────────────────────────────────────
  static const Color darkSurface       = Color(0xFF1A2E45);
  static const Color secondaryEmerald  = Color(0xFF006C49);
  static const Color accentMint        = Color(0xFF6CF8BB);
  static const Color alertYellow       = Color(0xFFF59E0B);

  // Health card gradient (deep dark teal matching Stitch hero card)
  static const Color healthCardGradientStart = Color(0xFF006A6A);
  static const Color healthCardGradientEnd   = Color(0xFF004F4F);

  // ── Light ThemeData ─────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFFFFECEC),
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
      surfaceTint: Color(0xFF006A6A),
    ),
    scaffoldBackgroundColor: surface,
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: primary, letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: onSurface),
    ),
    cardTheme: CardThemeData(
      color: surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: inverseSurface,
      selectedItemColor: primaryFixedDim,
      unselectedItemColor: Color(0x66FFFFFF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: outlineVariant, thickness: 1),
  );

  // ── Dark ThemeData ──────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryFixedDim,
      onPrimary: Color(0xFF002020),
      primaryContainer: Color(0xFF004F4F),
      onPrimaryContainer: Color(0xFF97F2F1),
      secondary: Color(0xFF4EDEA3),
      onSecondary: Color(0xFF002113),
      secondaryContainer: Color(0xFF005236),
      onSecondaryContainer: Color(0xFF6FFBBE),
      tertiary: Color(0xFFFFB3B6),
      onTertiary: Color(0xFF40000C),
      tertiaryContainer: Color(0xFF920028),
      onTertiaryContainer: Color(0xFFFFDADA),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0B1C30),
      onSurface: Color(0xFFD3E4FE),
      onSurfaceVariant: Color(0xFFBDC9C8),
      outline: Color(0xFF879393),
      outlineVariant: Color(0xFF3E4948),
      inverseSurface: Color(0xFFD3E4FE),
      onInverseSurface: Color(0xFF213145),
      inversePrimary: primary,
      surfaceTint: primaryFixedDim,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1C30),
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: primaryFixedDim, letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFD3E4FE)),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF16283E),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A2E45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryFixedDim, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryFixedDim,
        foregroundColor: const Color(0xFF002020),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A2E45),
      selectedItemColor: primaryFixedDim,
      unselectedItemColor: Color(0x66D3E4FE),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF3E4948), thickness: 1),
  );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light ? onSurface : const Color(0xFFD3E4FE);
    final Color subtitleColor = brightness == Brightness.light ? onSurfaceVariant : const Color(0xFFBDC9C8);
    return TextTheme(
      displayLarge:  GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: textColor),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: textColor),
      headlineLarge: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      titleLarge:    GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleMedium:   GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
      titleSmall:    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: subtitleColor),
      bodyLarge:     GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: textColor),
      bodyMedium:    GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      bodySmall:     GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtitleColor),
      labelLarge:    GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: textColor),
      labelMedium:   GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: subtitleColor),
      labelSmall:    GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: subtitleColor),
    );
  }

  // ── Elevation Shadows ───────────────────────────────────────────────────────
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: const Color(0xFF005F5F).withOpacity(0.05),
      blurRadius: 25, offset: const Offset(0, 10), spreadRadius: -5,
    ),
    BoxShadow(
      color: const Color(0xFF005F5F).withOpacity(0.05),
      blurRadius: 10, offset: const Offset(0, 8), spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16, offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get healthCardShadow => [
    BoxShadow(
      color: const Color(0xFF006A6A).withOpacity(0.40),
      blurRadius: 40, offset: const Offset(0, 20), spreadRadius: 0,
    ),
  ];
}
