import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightPrimaryColor = Color(0xFF6C63FF);
  static const Color lightSecondaryColor = Color(0xFFFF6B6B);
  static const Color lightSuccessColor = Color(0xFF00B894);
  static const Color lightWarningColor = Color(0xFFFDCB6E);
  static const Color lightDangerColor = Color(0xFFE17055);
  static const Color lightBackgroundColor = Color(0xFFF3F4F6);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightTextPrimaryColor = Color(0xFF1E293B);
  static const Color lightTextSecondaryColor = Color(0xFF475569);
  static const Color lightTextHintColor = Color(0xFF94A3B8);
  static const Color lightDividerColor = Color(0xFFE2E8F0);
  static const Color lightCardShadowColor = Color(0xFF000000);

  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFF818CF8);
  static const Color darkSecondaryColor = Color(0xFFFF6B6B);
  static const Color darkSuccessColor = Color(0xFF34D399);
  static const Color darkWarningColor = Color(0xFFFBBF24);
  static const Color darkDangerColor = Color(0xFFF87171);
  static const Color darkBackgroundStart = Color(0xFF0B0F17);
  static const Color darkBackgroundEnd = Color(0xFF111827);
  static const Color darkSurfaceColor = Color(0xFF1E293B);
  static const Color darkTextPrimaryColor = Color(0xFFF9FAFB);
  static const Color darkTextSecondaryColor = Color(0xFF94A3B8);
  static const Color darkTextHintColor = Color(0xFF64748B);
  static const Color darkDividerColor = Color(0xFF334155);
  static const Color darkCardShadowColor = Color(0xFF000000);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: lightSurfaceColor,
      dividerColor: lightDividerColor,
      colorScheme: const ColorScheme.light(
        primary: lightPrimaryColor,
        secondary: lightPrimaryColor,
        surface: lightSurfaceColor,
        background: lightBackgroundColor,
        error: lightDangerColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: lightTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        displaySmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
          letterSpacing: -0.3,
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: lightTextPrimaryColor,
        ),
        titleLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
        ),
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
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: lightBackgroundColor,
        foregroundColor: lightTextPrimaryColor,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimaryColor,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: lightTextPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightDividerColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightDangerColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: lightTextHintColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceColor,
        selectedColor: lightPrimaryColor.withOpacity(0.1),
        labelStyle: const TextStyle(color: lightTextPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: lightDividerColor.withOpacity(0.5)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: lightCardShadowColor.withOpacity(0.05),
        color: lightSurfaceColor,
        surfaceTintColor: lightSurfaceColor,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimaryColor,
      scaffoldBackgroundColor: darkBackgroundStart,
      cardColor: darkSurfaceColor,
      dividerColor: darkDividerColor,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimaryColor,
        secondary: darkPrimaryColor,
        surface: darkSurfaceColor,
        background: darkBackgroundStart,
        error: darkDangerColor,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        displaySmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
          letterSpacing: -0.5,
        ),
        headlineMedium: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
          letterSpacing: -0.3,
        ),
        headlineSmall: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: darkTextPrimaryColor,
        ),
        titleLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
        ),
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
          fontWeight: FontWeight.w500,
          color: darkBackgroundStart,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: darkBackgroundStart.withOpacity(0.8),
        foregroundColor: darkTextPrimaryColor,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimaryColor,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(
          color: darkTextPrimaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimaryColor,
          foregroundColor: darkBackgroundStart,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceColor.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkDividerColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDangerColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: darkTextHintColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceColor.withOpacity(0.6),
        selectedColor: darkPrimaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(color: darkTextPrimaryColor),
        secondaryLabelStyle: const TextStyle(color: darkBackgroundStart),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: darkDividerColor.withOpacity(0.3)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: darkCardShadowColor.withOpacity(0.4),
        color: darkSurfaceColor.withOpacity(0.6),
        surfaceTintColor: darkSurfaceColor.withOpacity(0.3),
      ),
    );
  }

  // Convenience aliases used across the app (keep as const to allow use in
  // `const` contexts like `BoxDecoration`).
  static const Color primaryColor = lightPrimaryColor;
  static const Color successColor = lightSuccessColor;
  static const Color dangerColor = lightDangerColor;
  static const Color darkBackgroundColor = darkBackgroundStart;
}
