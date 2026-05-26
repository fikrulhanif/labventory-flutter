import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/loan.dart';

/// Compact pill that maps a [LoanStatus] to a labeled, color-coded chip.
class LoanStatusChip extends StatelessWidget {
  const LoanStatusChip({super.key, required this.status, this.compact = false});

  final LoanStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _toneFor(status);
    final label = status.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static Color _toneFor(LoanStatus status) {
    return switch (status) {
      LoanStatus.pending => AppColors.statusPending,
      LoanStatus.approved => AppColors.statusApproved,
      LoanStatus.borrowed => AppColors.statusBorrowed,
      LoanStatus.returned => AppColors.statusReturned,
      LoanStatus.rejected => AppColors.statusRejected,
      LoanStatus.unknown => AppColors.statusRejected,
    };
  }
}
