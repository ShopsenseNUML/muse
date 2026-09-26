import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ShopSense theme — Dribbble-inspired modern shopping aesthetic.
///
/// Light mode: warm-neutral background (#F5F4F2), white cards, near-black
/// primary CTAs (#141414), lime/chartreuse accent (#A1D204) for badges,
/// ratings and active states, red for sales (#E5484D).
/// Dark mode: near-black background (#0B0B0B), dark surfaces (#161615),
/// lime primary CTAs — the established dark-mode idiom for shopping apps.
class AppTheme {
  // Light Theme Colors
  static const Color lightPrimaryColor = Color(0xFF141414);
  static const Color lightAccentColor = Color(0xFFA1D204);
  static const Color lightSecondaryColor = Color(0xFF0B3B2E);
  static const Color lightSuccessColor = Color(0xFF16A34A);
  static const Color lightWarningColor = Color(0xFFF59E0B);
  static const Color lightDangerColor = Color(0xFFE5484D);
  static const Color lightBackgroundColor = Color(0xFFF5F4F2);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightTextPrimaryColor = Color(0xFF111111);
  static const Color lightTextSecondaryColor = Color(0xFF6D6B69);
  static const Color lightTextHintColor = Color(0xFFA8A5A0);
  static const Color lightDividerColor = Color(0xFFE8E6E3);
  static const Color lightCardShadowColor = Color(0xFF1A1A1A);

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFFA1D204);
  static const Color darkAccentColor = Color(0xFFBDD51A);
  static const Color darkSecondaryColor = Color(0xFF34D399);
  static const Color darkSuccessColor = Color(0xFF34D399);
  static const Color darkWarningColor = Color(0xFFFBBF24);
  static const Color darkDangerColor = Color(0xFFF2555A);
  static const Color darkBackgroundStart = Color(0xFF0B0B0B);
  static const Color darkBackgroundEnd = Color(0xFF111111);
  static const Color darkSurfaceColor = Color(0xFF161615);
  static const Color darkTextPrimaryColor = Color(0xFFE8E8E8);
  static const Color darkTextSecondaryColor = Color(0xFFA0A0A4);
  static const Color darkTextHintColor = Color(0xFF6B6B6B);
  static const Color darkDividerColor = Color(0xFF262624);
  static const Color darkCardShadowColor = Color(0xFF000000);

  static TextTheme _headlineTextTheme(TextTheme base, Color color) =>
      GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -1.0,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -0.8,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: -0.2,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );

  static ThemeData get lightTheme {
    final headlines = _headlineTextTheme(
      GoogleFonts.interTextTheme(),
      lightTextPrimaryColor,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightSurfaceColor,
      dividerColor: lightDividerColor,
      colorScheme: const ColorScheme.light(
        primary: lightPrimaryColor,
        secondary: lightAccentColor,
        surface: lightSurfaceColor,
        error: lightDangerColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: headlines.displayLarge,
        displayMedium: headlines.displayMedium,
        displaySmall: headlines.displaySmall,
        headlineMedium: headlines.headlineMedium,
        headlineSmall: headlines.headlineSmall,
        titleLarge: headlines.titleLarge,
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextPrimaryColor,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextPrimaryColor,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextSecondaryColor,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: lightBackgroundColor,
        foregroundColor: lightTextPrimaryColor,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: lightTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: lightDividerColor.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightDangerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: lightTextHintColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceColor,
        selectedColor: lightAccentColor.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: lightTextPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: lightDividerColor.withValues(alpha: 0.7)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: lightCardShadowColor.withValues(alpha: 0.06),
        color: lightSurfaceColor,
        surfaceTintColor: lightSurfaceColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: lightPrimaryColor,
        unselectedItemColor: lightTextHintColor,
      ),
    );
  }

  static ThemeData get darkTheme {
    final headlines = _headlineTextTheme(
      GoogleFonts.interTextTheme(),
      darkTextPrimaryColor,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: darkBackgroundStart,
      cardColor: darkSurfaceColor,
      dividerColor: darkDividerColor,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkAccentColor,
        surface: darkSurfaceColor,
        error: darkDangerColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: headlines.displayLarge,
        displayMedium: headlines.displayMedium,
        displaySmall: headlines.displaySmall,
        headlineMedium: headlines.headlineMedium,
        headlineSmall: headlines.headlineSmall,
        titleLarge: headlines.titleLarge,
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: darkTextPrimaryColor,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: darkTextPrimaryColor,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: darkTextSecondaryColor,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0B0B0B),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: darkBackgroundStart.withValues(alpha: 0.85),
        foregroundColor: darkTextPrimaryColor,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: darkTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: darkTextPrimaryColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: const Color(0xFF0B0B0B),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor.withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: darkDividerColor.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkDangerColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: darkTextHintColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceColor.withValues(alpha: 0.8),
        selectedColor: darkPrimaryColor.withValues(alpha: 0.25),
        labelStyle: const TextStyle(color: darkTextPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: Color(0xFF0B0B0B)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: darkDividerColor.withValues(alpha: 0.6)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: darkCardShadowColor.withValues(alpha: 0.4),
        color: darkSurfaceColor,
        surfaceTintColor: darkSurfaceColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: darkPrimaryColor,
        unselectedItemColor: darkTextHintColor,
      ),
    );
  }

  // Convenience aliases used across the app.
  static const Color primaryColor = lightPrimaryColor;
  static const Color accentColor = lightAccentColor;
  static const Color successColor = lightSuccessColor;
  static const Color dangerColor = lightDangerColor;
  static const Color darkBackgroundColor = darkBackgroundStart;
}
