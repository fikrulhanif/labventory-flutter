import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/loan.dart';
import '../../providers/loan_provider.dart';
import '../../widgets/loan_status_chip.dart';

/// Read-only loan detail. Accepts the loan `id` via route arguments and
/// fetches via `LoanProvider.fetchDetail` so deep-links work too.
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
    final dateFmt = DateFormat('d MMM yyyy');
    final dateTimeFmt = DateFormat('d MMM yyyy · HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(loan == null ? 'Loan' : 'Loan #${loan.id}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : (loan == null
                ? Center(child: Text(_error ?? 'No loan selected.'))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              loan.inventory?.name ?? '—',
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          LoanStatusChip(status: loan.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loan.inventory?.code ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv(
                                theme,
                                'Borrow date',
                                loan.borrowDate == null
                                    ? '—'
                                    : dateFmt.format(loan.borrowDate!),
                              ),
                              _kv(
                                theme,
                                'Return date',
                                loan.returnDate == null
                                    ? '—'
                                    : dateFmt.format(loan.returnDate!),
                              ),
                              if (loan.pickedUpAt != null)
                                _kv(
                                  theme,
                                  'Picked up at',
                                  dateTimeFmt.format(
                                    loan.pickedUpAt!.toLocal(),
                                  ),
                                ),
                              if (loan.returnedAt != null)
                                _kv(
                                  theme,
                                  'Returned at',
                                  dateTimeFmt.format(
                                    loan.returnedAt!.toLocal(),
                                  ),
                                ),
                              if (loan.notes != null && loan.notes!.isNotEmpty)
                                _kv(theme, 'Notes', loan.notes!),
                              if (loan.rejectReason != null &&
                                  loan.rejectReason!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Rejection reason',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  loan.rejectReason!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
    );
  }

  Widget _kv(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
