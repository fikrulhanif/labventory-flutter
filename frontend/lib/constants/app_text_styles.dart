import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography presets for Labventory.
///
/// CRITICAL — all heading/body styles set an explicit `color` derived
/// from the active brightness. Earlier versions used
/// `GoogleFonts.inter(fontSize: ...)` without a base style, which
/// produces a fresh `TextStyle` with `color: null` and overrides the
/// inherited Material color. The result rendered as white-on-white on
/// light surfaces (see the regression visible in the inventory list
/// screenshot before this rewrite).
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(TextTheme base, Brightness brightness) {
    final primary = brightness == Brightness.light
        ? AppColors.textPrimary
        : AppColors.textPrimaryDark;
    final muted = brightness == Brightness.light
        ? AppColors.textMuted
        : AppColors.textMutedDark;

    return GoogleFonts.interTextTheme(base).copyWith(
      displaySmall: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.2,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.1,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: muted,
        letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: muted,
        letterSpacing: 0.5,
      ),
    );
  }

  /// AppBar title style.
  static TextStyle appBarTitle(Brightness brightness) {
    return GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: brightness == Brightness.light
          ? AppColors.textPrimary
          : AppColors.textPrimaryDark,
    );
  }
}
