import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Light/Vibrant palette inspired by reference UI ────────────
  static const Color background   = Color(0xFFF5F0FF);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color card         = Color(0xFFFFFFFF);
  static const Color cardLight    = Color(0xFFF0EBFF);

  // Primary purple gradient (like the reference)
  static const Color primary      = Color(0xFF7C5CFC);
  static const Color primaryLight = Color(0xFF9B7EFF);
  static const Color primaryDark  = Color(0xFF5A3DD8);

  static const Color accent       = Color(0xFFFF6B9D);   // pink
  static const Color accentBlue   = Color(0xFF4DA6FF);
  static const Color accentPurple = Color(0xFFB06EFF);
  static const Color accentYellow = Color(0xFFFFD166);
  static const Color accentGreen  = Color(0xFF06D6A0);
  static const Color accentOrange = Color(0xFFFF9F43);

  static const Color textPrimary   = Color(0xFF1A1040);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFFADB5BD);
  static const Color divider       = Color(0xFFEEE8FF);

  static const Color success = Color(0xFF06D6A0);
  static const Color warning = Color(0xFFFFD166);
  static const Color error   = Color(0xFFEF4444);

  // ── Gradients ─────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFFB06EFF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient heroBgGradient = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFF9B7EFF), Color(0xFFB06EFF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF9A5C)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF4DA6FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F4FF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  // ── Added missing gradients referenced by screen files ────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFB06EFF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFFB06EFF)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );

  static const LinearGradient onboardGradient1 = LinearGradient(
    colors: [Color(0xFF7C5CFC), Color(0xFF5A3DD8)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient onboardGradient2 = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF9A5C)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient onboardGradient3 = LinearGradient(
    colors: [Color(0xFF06D6A0), Color(0xFF4DA6FF)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient onboardGradient4 = LinearGradient(
    colors: [Color(0xFFFFD166), Color(0xFFFF9F43)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const LinearGradient onboardGradient5 = LinearGradient(
    colors: [Color(0xFFB06EFF), Color(0xFF7C5CFC)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: card, elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: primary.withOpacity(0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F0FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0D6FF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}

BoxDecoration cardDecoration({double radius = 20, Color? shadow}) {
  return BoxDecoration(
    color: AppTheme.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFEEE8FF), width: 1),
    boxShadow: [
      BoxShadow(
        color: (shadow ?? AppTheme.primary).withOpacity(0.08),
        blurRadius: 20, offset: const Offset(0, 6),
      ),
    ],
  );
}