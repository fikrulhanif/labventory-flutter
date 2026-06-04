import 'package:flutter/material.dart';

/// Brand palette for Labventory.
///
/// Single source of truth for tints used across screens so dark-mode
/// support and Bootstrap-aligned accents stay consistent. Designed to
/// pair with `ColorScheme.fromSeed(seedColor: AppColors.primary)`.
class AppColors {
  AppColors._();

  // ---- Brand ----
  static const Color primary = Color(0xFF6366F1); // indigo-500
  static const Color primaryDark = Color(0xFF4F46E5); // indigo-600
  static const Color secondary = Color(0xFF06B6D4); // cyan-500
  static const Color accent = Color(0xFFF97316); // orange-500

  // Gradient stops (used in cover cards and login hero).
  static const Color gradientStart = Color(0xFF6366F1);
  static const Color gradientEnd = Color(0xFF8B5CF6);
  static const Color heroBlobA = Color(0xFFA78BFA);
  static const Color heroBlobB = Color(0xFF22D3EE);

  // ---- Light neutrals ----
  static const Color background = Color(0xFFF6F7FB);
  static const Color surfaceLight = Colors.white;
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  // ---- Dark neutrals ----
  static const Color backgroundDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF161922);
  static const Color surfaceDarkElev = Color(0xFF1B1F2A);
  static const Color borderDark = Color(0xFF262B36);
  static const Color textPrimaryDark = Color(0xFFE5E7EB);
  static const Color textMutedDark = Color(0xFF9CA3AF);

  // Loan status colors (mirrors admin dashboard pills).
  static const Color statusPending = Color(0xFFF59E0B); // amber-500
  static const Color statusApproved = Color(0xFF06B6D4); // cyan-500
  static const Color statusBorrowed = Color(0xFF6366F1); // indigo-500
  static const Color statusReturned = Color(0xFF10B981); // emerald-500
  static const Color statusRejected = Color(0xFF6B7280); // gray-500

  // Feedback
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF06B6D4);
}
