import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/loan.dart';

/// Compact pill that maps a [LoanStatus] to a labeled, color-coded chip.
/// Pending loans get a subtle shimmer to signal they are still waiting.
class LoanStatusChip extends StatefulWidget {
  const LoanStatusChip({super.key, required this.status, this.compact = false});

  final LoanStatus status;
  final bool compact;

  @override
  State<LoanStatusChip> createState() => _LoanStatusChipState();
}

class _LoanStatusChipState extends State<LoanStatusChip>
    with SingleTickerProviderStateMixin {
  AnimationController? _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.status == LoanStatus.pending) {
      _shimmerCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shimmerCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _toneFor(widget.status);
    final label = widget.status.label;

    Widget chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 10,
        vertical: widget.compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: widget.compact ? 5 : 6,
            height: widget.compact ? 5 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: widget.compact ? 4 : 5),
          Text(
            label,
            style: TextStyle(
              fontSize: widget.compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    // Pending: animate opacity for a "waiting" pulsing feel
    if (_shimmerCtrl != null) {
      chip = AnimatedBuilder(
        animation: _shimmerCtrl!,
        builder: (context, child) =>
            Opacity(opacity: 0.70 + _shimmerCtrl!.value * 0.30, child: child),
        child: chip,
      );
    }

    return chip;
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
