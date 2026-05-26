import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography presets layered on top of [GoogleFonts.inter] so every
/// screen reads with the same hierarchy. Use these helpers via the
/// [BuildContext.textTheme] when possible; fall back to raw constants
/// in places where Theme is not available.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      headlineMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }
}
