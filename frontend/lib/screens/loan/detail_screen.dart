import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/loan_status_chip.dart';
import '../../widgets/skeleton.dart';
import 'ktm_viewer_screen.dart';

/// Read-only loan detail with a timeline visualization, KTM preview,
/// cancel button (pending only), countdown, and contextual notes.
class LoanDetailScreen extends StatefulWidget {
  const LoanDetailScreen({super.key});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  Loan? _loan;
  bool _loading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loan != null || _loading) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _fetch(args);
    } else if (args is Loan) {
      setState(() => _loan = args);
    }
  }

  Future<void> _fetch(int id) async {
    setState(() => _loading = true);
    final loan = await context.read<LoanProvider>().fetchDetail(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loan = loan;
      if (loan == null) _error = 'Tidak dapat memuat peminjaman #$id.';
    });
  }

  Future<void> _confirmCancel(BuildContext context, Loan loan) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Batalkan Peminjaman?'),
        content: Text(
          'Peminjaman "${loan.inventory?.name ?? '#${loan.id}'}" akan '
          'dibatalkan. Tindakan ini tidak dapat diurungkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final loanProvider = context.read<LoanProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await loanProvider.cancelLoan(loan.id);
    if (!mounted) return;

    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Peminjaman berhasil dibatalkan.'),
          backgroundColor: AppColors.statusReturned,
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loanProvider.submitError ?? 'Gagal membatalkan peminjaman.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = _loan;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loan == null ? 'Peminjaman' : 'Peminjaman #${loan.id}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _loading
          ? const _LoanDetailSkeleton()
          : (loan == null
                ? _ErrorBody(message: _error)
                : _LoanDetailBody(
                    loan: loan,
                    theme: theme,
                    onCancel: () => _confirmCancel(context, loan),
                  )),
    );
  }
}

// ---------------------------------------------------------------------

class _LoanDetailBody extends StatelessWidget {
  const _LoanDetailBody({
    required this.loan,
    required this.theme,
    required this.onCancel,
  });
  final Loan loan;
  final ThemeData theme;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isPending = loan.status == LoanStatus.pending;
    final isBorrowed = loan.status == LoanStatus.borrowed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusHero(loan: loan),
        const SizedBox(height: 12),

        // Countdown banner — shown when borrowed and return date is near
        if (isBorrowed && loan.returnDate != null)
          _CountdownBanner(returnDate: loan.returnDate!),

        const SizedBox(height: 12),
        _InventoryCard(loan: loan),
        const SizedBox(height: 16),
        _SectionTitle(text: 'Periode Peminjaman'),
        const SizedBox(height: 8),
        _PeriodCard(loan: loan),
        const SizedBox(height: 16),
        _SectionTitle(text: 'Kronologi Status'),
        const SizedBox(height: 8),
        _Timeline(loan: loan),
        if (loan.notes != null && loan.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle(text: 'Catatan'),
          const SizedBox(height: 8),
          _NotesCard(text: loan.notes!),
        ],
        if (loan.rejectReason != null && loan.rejectReason!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle(text: 'Alasan Penolakan'),
          const SizedBox(height: 8),
          _RejectionCard(reason: loan.rejectReason!),
        ],
        if (loan.documentUrl != null) ...[
          const SizedBox(height: 16),
          _SectionTitle(text: 'Dokumen KTM'),
          const SizedBox(height: 8),
          _KtmCard(loanId: loan.id, url: loan.documentUrl!),
        ],

        // Cancel button — only for pending loans
        if (isPending) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Batalkan Peminjaman'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

// ---------------------------------------------------------------------

class _CountdownBanner extends StatelessWidget {
  const _CountdownBanner({required this.returnDate});
  final DateTime returnDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final daysLeft = returnDate.difference(now).inDays;
    final overdue = daysLeft < 0;
    final urgent = !overdue && daysLeft <= 2;
    final accent = overdue
        ? AppColors.danger
        : urgent
        ? AppColors.statusPending
        : AppColors.statusReturned;

    final message = overdue
        ? 'Terlambat ${(-daysLeft)} hari — segera kembalikan alat!'
        : daysLeft == 0
        ? 'Harus dikembalikan HARI INI'
        : daysLeft == 1
        ? 'Harus dikembalikan BESOK'
        : 'Sisa $daysLeft hari sebelum jatuh tempo';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              overdue ? Icons.warning_rounded : Icons.access_time_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Batas: ${DateFormat('d MMMM yyyy').format(returnDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(loan.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [tone.withValues(alpha: 0.85), tone.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(_iconFor(loan.status), color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 12,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loan.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hintFor(loan.status),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(LoanStatus s) {
    return switch (s) {
      LoanStatus.pending => Icons.hourglass_top_outlined,
      LoanStatus.approved => Icons.thumb_up_outlined,
      LoanStatus.borrowed => Icons.local_shipping_outlined,
      LoanStatus.returned => Icons.check_circle_outline,
      LoanStatus.rejected => Icons.cancel_outlined,
      LoanStatus.unknown => Icons.help_outline,
    };
  }

  static Color _toneFor(LoanStatus s) {
    return switch (s) {
      LoanStatus.pending => AppColors.statusPending,
      LoanStatus.approved => AppColors.statusApproved,
      LoanStatus.borrowed => AppColors.statusBorrowed,
      LoanStatus.returned => AppColors.statusReturned,
      LoanStatus.rejected => AppColors.statusRejected,
      LoanStatus.unknown => AppColors.statusRejected,
    };
  }

  static String _hintFor(LoanStatus s) {
    return switch (s) {
      LoanStatus.pending => 'Menunggu lab meninjau permintaan Anda.',
      LoanStatus.approved => 'Disetujui! Ambil alat di konter lab.',
      LoanStatus.borrowed => 'Anda sedang meminjam alat ini.',
      LoanStatus.returned => 'Alat sudah dikembalikan. Terima kasih!',
      LoanStatus.rejected => 'Lihat alasan penolakan di bawah.',
      LoanStatus.unknown => '',
    };
  }
}

// ---------------------------------------------------------------------

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inv = loan.inventory;
    // Show "Pinjam Lagi" for returned or rejected (terminal) loans
    // that have an inventory reference.
    final isTerminal =
        loan.status == LoanStatus.returned ||
        loan.status == LoanStatus.rejected;
    final canBorrowAgain = isTerminal && inv != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv?.name ?? 'Inventaris',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (inv?.code != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.09,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                inv!.code,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (inv?.category != null)
                            Expanded(
                              child: Text(
                                inv!.category!.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                LoanStatusChip(status: loan.status, compact: true),
              ],
            ),
          ),

          // "Pinjam Lagi" button — only for completed/rejected loans
          if (canBorrowAgain) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
              indent: 14,
              endIndent: 14,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                children: [
                  Icon(
                    loan.status == LoanStatus.returned
                        ? Icons.replay_rounded
                        : Icons.shopping_bag_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loan.status == LoanStatus.returned
                          ? 'Pernah meminjam alat ini'
                          : 'Tertarik meminjam alat ini?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Gradient "Pinjam Lagi" button
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRouter.inventoryDetail, arguments: inv),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gradientStart.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Pinjam Lagi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.loan});
  final Loan loan;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d MMM yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _DateBox(
                label: 'Pinjam',
                value: loan.borrowDate == null
                    ? '—'
                    : df.format(loan.borrowDate!),
                icon: Icons.event_available_outlined,
                color: AppColors.statusBorrowed,
              ),
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: _DateBox(
                label: 'Kembali',
                value: loan.returnDate == null
                    ? '—'
                    : df.format(loan.returnDate!),
                icon: Icons.assignment_returned_outlined,
                color: AppColors.statusReturned,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------

class _Timeline extends StatelessWidget {
  const _Timeline({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final dt = DateFormat('d MMM yyyy, HH:mm');

    final entries = <_Step>[
      _Step(
        title: 'Dikirim',
        subtitle: loan.createdAt == null
            ? 'Permintaan dibuat'
            : dt.format(loan.createdAt!.toLocal()),
        done: true,
        icon: Icons.send_outlined,
      ),
      _Step(
        title: loan.status == LoanStatus.rejected ? 'Ditolak' : 'Disetujui',
        subtitle: loan.status == LoanStatus.rejected
            ? (loan.updatedAt == null
                  ? 'Permintaan ditolak'
                  : dt.format(loan.updatedAt!.toLocal()))
            : (loan.status == LoanStatus.pending
                  ? 'Menunggu persetujuan'
                  : 'Lab menyetujui permintaan Anda'),
        done:
            loan.status == LoanStatus.approved ||
            loan.status == LoanStatus.borrowed ||
            loan.status == LoanStatus.returned ||
            loan.status == LoanStatus.rejected,
        rejected: loan.status == LoanStatus.rejected,
        icon: loan.status == LoanStatus.rejected
            ? Icons.cancel_outlined
            : Icons.thumb_up_outlined,
      ),
      _Step(
        title: 'Diambil',
        subtitle: loan.pickedUpAt == null
            ? 'Alat belum diambil'
            : dt.format(loan.pickedUpAt!.toLocal()),
        done: loan.pickedUpAt != null,
        icon: Icons.local_shipping_outlined,
      ),
      _Step(
        title: 'Dikembalikan',
        subtitle: loan.returnedAt == null
            ? 'Alat belum dikembalikan'
            : dt.format(loan.returnedAt!.toLocal()),
        done: loan.returnedAt != null,
        icon: Icons.check_circle_outline,
      ),
    ];

    // For rejected loans, only show the first two steps.
    final visible = loan.status == LoanStatus.rejected
        ? entries.take(2).toList()
        : entries;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++)
              _TimelineRow(
                step: visible[i],
                isLast: i == visible.length - 1,
                isFirst: i == 0,
                nextDone: i + 1 < visible.length && visible[i + 1].done,
              ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.icon,
    this.rejected = false,
  });
  final String title;
  final String subtitle;
  final bool done;
  final bool rejected;
  final IconData icon;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.isLast,
    required this.isFirst,
    required this.nextDone,
  });
  final _Step step;
  final bool isLast;
  final bool isFirst;
  final bool nextDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = step.rejected
        ? AppColors.statusRejected
        : step.done
        ? AppColors.statusReturned
        : theme.colorScheme.outline;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: activeColor, width: 1.4),
                ),
                child: Icon(step.icon, size: 16, color: activeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: nextDone
                        ? AppColors.statusReturned.withValues(alpha: 0.50)
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: step.done || step.rejected
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(step.subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.format_quote, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _RejectionCard extends StatelessWidget {
  const _RejectionCard({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.30),
          width: 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KtmCard extends StatelessWidget {
  const _KtmCard({required this.loanId, required this.url});
  final int loanId;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.badge_outlined, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kartu Identitas', style: theme.textTheme.titleSmall),
                  Text(
                    'Ketuk untuk lihat di aplikasi',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => KtmViewerScreen(
                    // Backend serves the file at /api/loans/{id}/document.
                    // We pass the path (relative to the Dio baseUrl) so
                    // the auth interceptor attaches the Bearer token.
                    path: '/loans/$loanId/document',
                    title: 'KTM · Loan #$loanId',
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String? message;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message ?? 'Tidak ada peminjaman dipilih.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanDetailSkeleton extends StatelessWidget {
  const _LoanDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Skeleton(width: double.infinity, height: 96, radius: 20),
        SizedBox(height: 16),
        Skeleton(width: double.infinity, height: 76, radius: 20),
        SizedBox(height: 16),
        Skeleton(width: 80, height: 14),
        SizedBox(height: 8),
        Skeleton(width: double.infinity, height: 120, radius: 20),
        SizedBox(height: 16),
        Skeleton(width: 100, height: 14),
        SizedBox(height: 8),
        Skeleton(width: double.infinity, height: 220, radius: 20),
      ],
    );
  }
}
