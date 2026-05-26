import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography presets layered on top of [GoogleFonts.inter] so every
/// screen reads with the same hierarchy. Use these helpers via the
/// [BuildContext.textTheme] when possible; fall back to raw constants
/// in places where Theme is not available.
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(TextTheme base) {
    // Apply Inter as the font family while preserving the inherited
    // colors from `base` (Material's default onSurface/onBackground).
    // Using `GoogleFonts.inter(textStyle: ...)` is critical: calling
    // `GoogleFonts.inter(fontSize: ...)` without a base style creates a
    // brand new TextStyle with `color: null`, which silently nukes the
    // inherited text color and renders as invisible/white on light
    // surfaces.
    final inter = GoogleFonts.interTextTheme(base);

    return inter.copyWith(
      headlineMedium: GoogleFonts.inter(
        textStyle: inter.headlineMedium,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.inter(
        textStyle: inter.titleLarge,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        textStyle: inter.titleMedium,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: inter.bodyLarge,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: inter.bodyMedium,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: inter.labelMedium,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }
}
