import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/loan.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/loan_status_chip.dart';

/// Shows the scanned inventory and its active loans. The admin picks a
/// loan then confirms handover (approved → borrowed) or return
/// (borrowed → returned) (Requirement 22).
class AdminLoanActionScreen extends StatelessWidget {
  const AdminLoanActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final inventory = admin.inventory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Aktif'),
        // Show a subtle loading indicator in the app-bar while acting.
        bottom: admin.isActing
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
      body: inventory == null
          ? const _EmptyState()
          : _Body(admin: admin, theme: theme),
      bottomNavigationBar: (inventory == null || admin.loans.isEmpty)
          ? null
          : const _ActionBar(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.admin, required this.theme});

  final AdminProvider admin;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        // Make sure nothing hides under the action bar
        admin.loans.isEmpty ? 24 : 100,
      ),
      children: [
        _InventoryCard(admin: admin),
        const SizedBox(height: 20),

        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Transaksi Aktif',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              if (admin.loans.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${admin.loans.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (admin.loans.isEmpty)
          _EmptyActiveLoans()
        else ...[
          if (admin.loans.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                'Pilih transaksi yang ingin diproses:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ...admin.loans.map(
            (loan) => _LoanCard(
              loan: loan,
              selected: admin.selectedLoan?.id == loan.id,
              onTap: () => context.read<AdminProvider>().selectLoan(loan),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory summary card
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.admin});
  final AdminProvider admin;

  @override
  Widget build(BuildContext context) {
    final inv = admin.inventory!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (inv.category != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          inv.category!.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatPill(icon: Icons.qr_code_rounded, label: inv.code),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.inventory_outlined,
                  label: 'Stok: ${inv.stock}',
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: inv.stock > 0
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  label: inv.stock > 0 ? 'Tersedia' : 'Habis',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan transaction card
// ─────────────────────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.loan,
    required this.selected,
    required this.onTap,
  });

  final Loan loan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('d MMM yyyy');
    final student = loan.user;

    // Accent colour per status
    final accent = loan.status == LoanStatus.approved
        ? AppColors.statusApproved
        : AppColors.statusBorrowed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initial(student?.name),
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.name ?? '—',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student?.nim != null
                                ? 'NIM ${student!.nim!}'
                                : student?.email ?? '—',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LoanStatusChip(status: loan.status),
                  ],
                ),
              ),

              // ── Divider ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),

              // ── Detail grid ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tanggal Pinjam',
                      value: loan.borrowDate != null
                          ? df.format(loan.borrowDate!)
                          : '—',
                    ),
                    const SizedBox(height: 6),
                    _DetailRow(
                      icon: Icons.event_available_outlined,
                      label: 'Rencana Kembali',
                      value: loan.returnDate != null
                          ? df.format(loan.returnDate!)
                          : '—',
                    ),
                    if (loan.pickedUpAt != null) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                        icon: Icons.outbox_outlined,
                        label: 'Diserahkan',
                        value: DateFormat(
                          'd MMM yyyy, HH:mm',
                        ).format(loan.pickedUpAt!.toLocal()),
                        valueColor: AppColors.statusBorrowed,
                      ),
                    ],
                    if (loan.notes != null && loan.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _DetailRow(
                        icon: Icons.notes_outlined,
                        label: 'Catatan',
                        value: loan.notes!,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Selection indicator bar ────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: selected ? 38 : 0,
                curve: Curves.easeOutCubic,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: selected
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Dipilih — lihat tombol di bawah',
                            style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initial(String? name) {
    final t = (name ?? '').trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyActiveLoans extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            'Tidak ada transaksi aktif',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inventaris ini tidak memiliki peminjaman yang disetujui '
            'atau sedang dipinjam saat ini.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Tidak ada data inventaris.'));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action bar
// ─────────────────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final theme = Theme.of(context);
    final selected = admin.selectedLoan;

    final bool isApproved = selected?.status == LoanStatus.approved;
    final bool isBorrowed = selected?.status == LoanStatus.borrowed;

    final String label;
    final IconData icon;
    final Color color;
    final String? subLabel;

    if (isApproved) {
      label = 'Serahkan Inventaris';
      icon = Icons.outbox_rounded;
      color = AppColors.statusApproved;
      subLabel = 'approved → dipinjam · stok −1';
    } else if (isBorrowed) {
      label = 'Terima Pengembalian';
      icon = Icons.move_to_inbox_rounded;
      color = AppColors.statusReturned;
      subLabel = 'dipinjam → dikembalikan · stok +1';
    } else {
      label = 'Pilih transaksi di atas';
      icon = Icons.touch_app_outlined;
      color = theme.colorScheme.outlineVariant;
      subLabel = null;
    }

    final canAct = (isApproved || isBorrowed) && !admin.isActing;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (subLabel != null && canAct)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  subLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: canAct ? color : null,
                  foregroundColor: canAct ? Colors.white : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: canAct ? () => _confirmAndAct(context) : null,
                icon: admin.isActing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(icon),
                label: Text(
                  admin.isActing ? 'Memproses...' : label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndAct(BuildContext context) async {
    final admin = context.read<AdminProvider>();
    final selected = admin.selectedLoan;
    if (selected == null) return;

    final isApproved = selected.status == LoanStatus.approved;
    final actionLabel = isApproved
        ? 'Serahkan Inventaris'
        : 'Terima Pengembalian';
    final studentName = selected.user?.name ?? 'mahasiswa ini';
    final df = DateFormat('d MMM yyyy');
    final inventory = admin.inventory;

    // Rich confirmation dialog with full context
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Icon(
              isApproved ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
              color: isApproved
                  ? AppColors.statusApproved
                  : AppColors.statusReturned,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConfirmRow(label: 'Mahasiswa', value: studentName),
            if (selected.user?.nim != null)
              _ConfirmRow(label: 'NIM', value: selected.user!.nim!),
            _ConfirmRow(label: 'Inventaris', value: inventory?.name ?? '—'),
            _ConfirmRow(label: 'Kode', value: inventory?.code ?? '—'),
            if (selected.borrowDate != null)
              _ConfirmRow(
                label: 'Tgl. Pinjam',
                value: df.format(selected.borrowDate!),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    (isApproved
                            ? AppColors.statusApproved
                            : AppColors.statusReturned)
                        .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isApproved
                    ? '✦ Stok akan berkurang 1 setelah konfirmasi.'
                    : '✦ Stok akan bertambah 1 setelah konfirmasi.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isApproved
                      ? AppColors.statusApproved
                      : AppColors.statusReturned,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isApproved
                  ? AppColors.statusApproved
                  : AppColors.statusReturned,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final message = isApproved
        ? await admin.handover(selected.id)
        : await admin.returnLoan(selected.id);

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (message != null) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isApproved
                      ? 'Inventaris berhasil diserahkan kepada $studentName.'
                      : 'Pengembalian dari $studentName berhasil diterima.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      if (admin.loans.isEmpty && context.mounted) {
        Navigator.of(context).pop();
      }
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  admin.errorMessage ?? 'Aksi gagal diproses.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
