import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loan_status_chip.dart';
import '../../widgets/skeleton.dart';
import '../shell/app_shell.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<LoanHistoryScreen> createState() => _LoanHistoryScreenState();
}

class _LoanHistoryScreenState extends State<LoanHistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LoanProvider>();
      if (provider.state == LoanHistoryState.idle) provider.loadHistory();
    });
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<LoanProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LoanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peminjaman Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: !widget.embeddedInShell,
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
      body: Column(
        children: [
          _StatBanner(loans: provider.items),
          _StatusFilterChips(provider: provider),
          Expanded(
            child: _Body(provider: provider, scroll: _scrollController),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatBanner extends StatelessWidget {
  const _StatBanner({required this.loans});
  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) return const SizedBox.shrink();

    final pending = loans.where((l) => l.status == LoanStatus.pending).length;
    final active = loans
        .where(
          (l) =>
              l.status == LoanStatus.approved ||
              l.status == LoanStatus.borrowed,
        )
        .length;
    final returned = loans.where((l) => l.status == LoanStatus.returned).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _BannerStat(
              label: 'Menunggu',
              value: '$pending',
              icon: Icons.hourglass_top_outlined,
            ),
            _BannerDivider(),
            _BannerStat(
              label: 'Aktif',
              value: '$active',
              icon: Icons.local_shipping_outlined,
            ),
            _BannerDivider(),
            _BannerStat(
              label: 'Selesai',
              value: '$returned',
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.28),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.provider});
  final LoanProvider provider;

  static Color _colorFor(LoanStatus s) {
    return switch (s) {
      LoanStatus.pending => AppColors.statusPending,
      LoanStatus.approved => AppColors.statusApproved,
      LoanStatus.borrowed => AppColors.statusBorrowed,
      LoanStatus.returned => AppColors.statusReturned,
      LoanStatus.rejected => AppColors.statusRejected,
      LoanStatus.unknown => AppColors.statusRejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = provider.statusFilter;
    const filters = [
      LoanStatus.pending,
      LoanStatus.approved,
      LoanStatus.borrowed,
      LoanStatus.returned,
      LoanStatus.rejected,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "Semua" chip
            GestureDetector(
              onTap: () => provider.setStatusFilter(null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selected == null
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected == null
                        ? AppColors.primary.withValues(alpha: 0.55)
                        : theme.colorScheme.outline,
                    width: selected == null ? 1.3 : 0.6,
                  ),
                ),
                child: Text(
                  'Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: selected == null
                        ? AppColors.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...filters.map((status) {
              final isSelected = selected == status;
              final color = _colorFor(status);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () =>
                      provider.setStatusFilter(isSelected ? null : status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.14)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.55)
                            : theme.colorScheme.outline,
                        width: isSelected ? 1.3 : 0.6,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.scroll});
  final LoanProvider provider;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    if (provider.state == LoanHistoryState.loading) {
      return const SkeletonList();
    }

    if (provider.state == LoanHistoryState.error && provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Gagal memuat peminjaman',
        message: provider.errorMessage,
        action: FilledButton(
          onPressed: () => provider.loadHistory(refresh: true),
          child: const Text('Coba Lagi'),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Belum ada peminjaman',
        message:
            'Jelajahi inventaris dan ajukan peminjaman pertama Anda — hanya butuh beberapa menit.',
        action: FilledButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Jelajahi Inventaris'),
          onPressed: () => AppShell.of(context)?.setIndex(1),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadHistory(refresh: true),
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
        itemCount: provider.items.length + (provider.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final loan = provider.items[index];
          final card = _LoanCard(loan: loan);
          if (index >= 10) return card;
          return TweenAnimationBuilder<double>(
            key: ValueKey('loan-${loan.id}'),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 260 + index * 40),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 14),
                child: child,
              ),
            ),
            child: card,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan card
// ─────────────────────────────────────────────────────────────────────────────

class _LoanCard extends StatefulWidget {
  const _LoanCard({required this.loan});
  final Loan loan;

  @override
  State<_LoanCard> createState() => _LoanCardState();
}

class _LoanCardState extends State<_LoanCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = widget.loan;
    final dateFmt = DateFormat('d MMM yyyy');
    final tone = _toneFor(loan.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.98),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          Navigator.of(
            context,
          ).pushNamed(AppRouter.loanDetail, arguments: loan.id);
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Status accent strip
                    Container(width: 4, color: tone),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: tone.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: Icon(
                                    _iconFor(loan.status),
                                    color: tone,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        loan.inventory?.name ??
                                            'Peminjaman #${loan.id}',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (loan.inventory?.code != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.09),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                loan.inventory!.code,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            if (loan.inventory?.category !=
                                                null) ...[
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  loan
                                                      .inventory!
                                                      .category!
                                                      .name,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                LoanStatusChip(
                                  status: loan.status,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Date row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event_outlined,
                                    size: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      loan.borrowDate != null &&
                                              loan.returnDate != null
                                          ? '${dateFmt.format(loan.borrowDate!)} → ${dateFmt.format(loan.returnDate!)}'
                                          : '—',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  if (loan.createdAt != null) ...[
                                    Icon(
                                      Icons.access_time,
                                      size: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _relative(loan.createdAt!),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Chevron
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _relative(DateTime d) {
    final delta = DateTime.now().difference(d);
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}j';
    if (delta.inDays < 7) return '${delta.inDays}h';
    return DateFormat('d MMM').format(d);
  }

  static IconData _iconFor(LoanStatus s) => switch (s) {
    LoanStatus.pending => Icons.hourglass_top_outlined,
    LoanStatus.approved => Icons.thumb_up_outlined,
    LoanStatus.borrowed => Icons.local_shipping_outlined,
    LoanStatus.returned => Icons.check_circle_outline,
    LoanStatus.rejected => Icons.cancel_outlined,
    LoanStatus.unknown => Icons.help_outline,
  };

  static Color _toneFor(LoanStatus s) => switch (s) {
    LoanStatus.pending => AppColors.statusPending,
    LoanStatus.approved => AppColors.statusApproved,
    LoanStatus.borrowed => AppColors.statusBorrowed,
    LoanStatus.returned => AppColors.statusReturned,
    LoanStatus.rejected => AppColors.statusRejected,
    LoanStatus.unknown => AppColors.statusRejected,
  };
}
