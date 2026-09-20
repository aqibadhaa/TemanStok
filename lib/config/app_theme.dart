import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14A098);
  static const Color gold = Color(0xFFBAA070);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  static const Color statusKritis = Color(0xFFE53935);
  static const Color statusRendah = Color(0xFFF59E0B);
  static const Color statusAman = Color(0xFF0D7377);

  static const Color micScreenBg = Color(0xFF0D1B2A);

  // Border Radius
  static const double radiusCard = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusBadge = 20.0;
  static const double radiusBottomSheet = 20.0;

  // Spacing
  static const double pagePadding = 20.0;
  static const double cardPadding = 16.0;
  static const double cardGap = 12.0;

  // Typography
  static TextStyle headingBold = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle headingMedium = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
  );

  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
  );

  // Theme helper
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        titleLarge: headingBold,
        titleMedium: headingMedium,
        bodyLarge: body,
        bodySmall: caption,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
