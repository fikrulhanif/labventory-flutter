import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/inventory_card.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventoryProvider>();
      // First-time load only; subsequent visits re-use existing state.
      if (provider.state == InventoryListState.idle) {
        provider.bootstrap();
      }
    });
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<InventoryProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppSearchBar(
              hint: 'Search by name or code…',
              initialValue: provider.search,
              onChanged: provider.setSearch,
            ),
          ),
          const SizedBox(height: 8),
          _FilterRow(provider: provider),
          const SizedBox(height: 4),
          Expanded(child: _Body(provider: provider)),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.provider});

  final InventoryProvider provider;

  @override
  Widget build(BuildContext context) {
    final categories = provider.categories;
    final hasFilter =
        provider.search.isNotEmpty ||
        provider.categoryId != null ||
        provider.statusFilter != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatusFilter(
              value: provider.statusFilter,
              onChanged: provider.setStatusFilter,
            ),
            const SizedBox(width: 8),
            ...categories.map(
              (c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c.name),
                  selected: provider.categoryId == c.id,
                  onSelected: (selected) {
                    provider.setCategoryId(selected ? c.id : null);
                  },
                ),
              ),
            ),
            if (hasFilter)
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: provider.clearFilters,
                label: const Text('Reset'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChoiceChip(
          label: const Text('Available'),
          selected: value == 'available',
          onSelected: (s) => onChanged(s ? 'available' : null),
        ),
        const SizedBox(width: 6),
        ChoiceChip(
          label: const Text('Out of stock'),
          selected: value == 'out_of_stock',
          onSelected: (s) => onChanged(s ? 'out_of_stock' : null),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider});

  final InventoryProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.state == InventoryListState.loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (provider.state == InventoryListState.error && provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load inventory',
        message: provider.errorMessage,
        action: FilledButton(
          onPressed: provider.refresh,
          child: const Text('Try again'),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No items match your filters',
        message:
            'Try clearing the filters or searching with a different keyword.',
        action: TextButton(
          onPressed: provider.clearFilters,
          child: const Text('Reset filters'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        controller: (context
            .findAncestorStateOfType<_InventoryListScreenState>()
            ?._scrollController),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: provider.items.length + (provider.hasNextPage ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final inventory = provider.items[index];
          return InventoryCard(
            inventory: inventory,
            onTap: () => _openDetail(context, inventory),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Inventory inventory) {
    Navigator.of(
      context,
    ).pushNamed(AppRouter.inventoryDetail, arguments: inventory);
  }
}
