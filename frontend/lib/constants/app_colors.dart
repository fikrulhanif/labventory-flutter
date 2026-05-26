import 'package:flutter/material.dart';

/// Brand palette for Labventory.
///
/// Single source of truth for tints used across screens so dark-mode
/// support and Bootstrap-aligned accents stay consistent.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF4F46E5); // indigo-600
  static const Color primaryDark = Color(0xFF4338CA); // indigo-700
  static const Color accent = Color(0xFF8B5CF6); // violet-500

  // Neutrals
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  // Loan status colors (mirrors admin dashboard badges)
  static const Color statusPending = Color(0xFFF59E0B); // amber-500
  static const Color statusApproved = Color(0xFF06B6D4); // cyan-500
  static const Color statusBorrowed = Color(0xFF4F46E5); // indigo-600
  static const Color statusReturned = Color(0xFF10B981); // emerald-500
  static const Color statusRejected = Color(0xFF6B7280); // gray-500

  // Feedback
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}
