import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/loan_status_chip.dart';
import '../../widgets/skeleton.dart';
import 'ktm_viewer_screen.dart';

/// Read-only loan detail with a timeline visualization, KTM preview,
/// and contextual notes. Accepts the loan `id` (route arguments) or a
/// hydrated `Loan` instance.
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
      if (loan == null) _error = 'Could not load loan #$id.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = _loan;

    return Scaffold(
      appBar: AppBar(
        title: Text(loan == null ? 'Peminjaman' : 'Peminjaman #${loan.id}'),
      ),
      body: _loading
          ? const _LoanDetailSkeleton()
          : (loan == null
                ? _ErrorBody(message: _error)
                : _LoanDetailBody(loan: loan, theme: theme)),
    );
  }
}

// ---------------------------------------------------------------------

class _LoanDetailBody extends StatelessWidget {
  const _LoanDetailBody({required this.loan, required this.theme});
  final Loan loan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusHero(loan: loan),
        const SizedBox(height: 16),
        _InventoryCard(loan: loan),
        const SizedBox(height: 16),
        _SectionTitle(text: 'Periode'),
        const SizedBox(height: 8),
        _PeriodCard(loan: loan),
        const SizedBox(height: 16),
        _SectionTitle(text: 'Kronologi'),
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
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.loan});
  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    // ignore: dead_code
    theme; // reserved
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.inventory?.name ?? 'Inventaris',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loan.inventory?.code ?? '—',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            LoanStatusChip(status: loan.status, compact: true),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
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
