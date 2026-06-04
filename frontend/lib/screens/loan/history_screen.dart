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
      if (provider.state == LoanHistoryState.idle) {
        provider.loadHistory();
      }
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
    final loanProvider = context.watch<LoanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My loans'),
        automaticallyImplyLeading: !widget.embeddedInShell,
      ),
      body: Column(
        children: [
          _StatBanner(loans: loanProvider.items),
          _StatusFilterChips(provider: loanProvider),
          Expanded(
            child: _Body(provider: loanProvider, scroll: _scrollController),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Stat banner — quick read of loan distribution by status
// ---------------------------------------------------------------------

class _StatBanner extends StatelessWidget {
  const _StatBanner({required this.loans});
  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
            label: 'Pending',
            value: pending.toString(),
            icon: Icons.hourglass_top_outlined,
          ),
          _BannerDivider(),
          _BannerStat(
            label: 'Active',
            value: active.toString(),
            icon: Icons.local_shipping_outlined,
          ),
          _BannerDivider(),
          _BannerStat(
            label: 'Returned',
            value: returned.toString(),
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
    // ignore: dead_code
    theme; // keep theme reachable if future versions need it
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
      height: 28,
      color: Colors.white.withValues(alpha: 0.30),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ---------------------------------------------------------------------

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.provider});

  final LoanProvider provider;

  @override
  Widget build(BuildContext context) {
    final selected = provider.statusFilter;
    final filters = const [
      LoanStatus.pending,
      LoanStatus.approved,
      LoanStatus.borrowed,
      LoanStatus.returned,
      LoanStatus.rejected,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => provider.setStatusFilter(null),
          ),
          const SizedBox(width: 6),
          ...filters.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(status.label),
                selected: selected == status,
                onSelected: (s) => provider.setStatusFilter(s ? status : null),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
        title: 'Could not load loans',
        message: provider.errorMessage,
        action: FilledButton(
          onPressed: () => provider.loadHistory(refresh: true),
          child: const Text('Try again'),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No loan requests yet',
        message:
            'Browse the inventory and submit your first loan request — it only takes a minute.',
        action: FilledButton.icon(
          icon: const Icon(Icons.search),
          label: const Text('Browse inventory'),
          onPressed: () => AppShell.of(context)?.setIndex(1),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadHistory(refresh: true),
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
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
          if (index >= 8) return card;
          return TweenAnimationBuilder<double>(
            key: ValueKey('loan-${loan.id}'),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 280 + index * 40),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 12),
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

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('d MMM yyyy');
    final tone = _toneFor(loan.status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRouter.loanDetail, arguments: loan.id),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Color accent strip — instantly readable status
                Container(width: 4, color: tone),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: tone.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loan.inventory?.name ?? 'Loan #${loan.id}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (loan.inventory?.code != null)
                                    Text(
                                      loan.inventory!.code,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            LoanStatusChip(status: loan.status, compact: true),
                          ],
                        ),
                        const SizedBox(height: 10),
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
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  loan.borrowDate != null &&
                                          loan.returnDate != null
                                      ? '${dateFmt.format(loan.borrowDate!)} → ${dateFmt.format(loan.returnDate!)}'
                                      : 'No dates',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              if (loan.createdAt != null) ...[
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _relative(loan.createdAt!),
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _relative(DateTime d) {
    final delta = DateTime.now().difference(d);
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    if (delta.inDays < 7) return '${delta.inDays}d';
    return DateFormat('d MMM').format(d);
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
}
