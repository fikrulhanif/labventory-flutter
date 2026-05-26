import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loan_status_chip.dart';

class LoanHistoryScreen extends StatefulWidget {
  const LoanHistoryScreen({super.key});

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
      appBar: AppBar(title: const Text('My loans')),
      body: Column(
        children: [
          _StatusFilterChips(provider: loanProvider),
          Expanded(
            child: _Body(provider: loanProvider, scroll: _scrollController),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
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
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No loan requests yet',
        message:
            'Pick an item from the inventory to submit your first request.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadHistory(refresh: true),
      child: ListView.builder(
        controller: scroll,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: provider.items.length + (provider.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return _LoanRow(loan: provider.items[index]);
        },
      ),
    );
  }
}

class _LoanRow extends StatelessWidget {
  const _LoanRow({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('d MMM yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRouter.loanDetail, arguments: loan.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loan.inventory?.name ??
                          'Inventory #${loan.inventory?.id ?? '-'}',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  LoanStatusChip(status: loan.status),
                ],
              ),
              const SizedBox(height: 4),
              if (loan.inventory?.code != null)
                Text(
                  loan.inventory!.code,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    loan.borrowDate != null && loan.returnDate != null
                        ? '${dateFmt.format(loan.borrowDate!)} → ${dateFmt.format(loan.returnDate!)}'
                        : '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
