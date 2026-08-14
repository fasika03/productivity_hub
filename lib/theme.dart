import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const inkDark = Color(0xFF1C2B24);
  static const inkDarker = Color(0xFF131F19);
  static const parchment = Color(0xFFF2ECDC);
  static const parchmentSoft = Color(0xFFE9E0C6);
  static const parchmentLine = Color(0xFFD8CBA0);
  static const gold = Color(0xFFC89B3C);
  static const goldSoft = Color(0xFFE0BE73);
  static const terracotta = Color(0xFFB5654A);
  static const sage = Color(0xFF6B8F71);
  static const textDark = Color(0xFF23301F);
  static const textMuted = Color(0xFF5B6656);
  static const textLight = Color(0xFFF2ECDC);
  static const white = Color(0xFFFFFFFF);
}

TextStyle displayFont({double size = 20, FontWeight weight = FontWeight.w700, Color? color}) {
  return GoogleFonts.fraunces(fontSize: size, fontWeight: weight, color: color ?? AppColors.inkDark);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.parchment,
    fontFamily: GoogleFonts.inter().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      primary: AppColors.inkDark,
      secondary: AppColors.gold,
      surface: AppColors.parchment,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.inkDarker,
      foregroundColor: AppColors.textLight,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.fraunces(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.parchmentLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.parchmentLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
  );
}
