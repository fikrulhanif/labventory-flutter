import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/inventory_card.dart';
import '../../widgets/skeleton.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  bool _isGridView = false;

  late final AnimationController _viewToggleCtrl;

  @override
  void initState() {
    super.initState();
    _viewToggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InventoryProvider>();
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

  void _toggleView() {
    setState(() => _isGridView = !_isGridView);
    if (_isGridView) {
      _viewToggleCtrl.forward();
    } else {
      _viewToggleCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewToggleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris'),
        automaticallyImplyLeading: !widget.embeddedInShell,
        actions: [
          // Grid/list view toggle
          AnimatedBuilder(
            animation: _viewToggleCtrl,
            builder: (context, _) => IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  key: ValueKey(_isGridView),
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: _toggleView,
              tooltip: _isGridView ? 'List view' : 'Grid view',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppSearchBar(
              hint: 'Cari berdasarkan nama atau kode…',
              initialValue: provider.search,
              onChanged: provider.setSearch,
              hasActiveFilter:
                  provider.categoryId != null || provider.statusFilter != null,
            ),
          ),
          const SizedBox(height: 8),
          _FilterRow(provider: provider),
          const SizedBox(height: 4),
          // Item count banner
          if (provider.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${provider.items.length} barang',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (provider.hasNextPage) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(lebih banyak tersedia)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: _Body(
              provider: provider,
              scrollController: _scrollController,
              isGridView: _isGridView,
            ),
          ),
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

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _StyledChip(
            label: 'Tersedia',
            selected: provider.statusFilter == 'available',
            color: AppColors.statusReturned,
            icon: Icons.check_circle_outline,
            onSelected: (s) => provider.setStatusFilter(s ? 'available' : null),
          ),
          const SizedBox(width: 6),
          _StyledChip(
            label: 'Stok Habis',
            selected: provider.statusFilter == 'out_of_stock',
            color: AppColors.statusRejected,
            icon: Icons.do_not_disturb_alt_outlined,
            onSelected: (s) =>
                provider.setStatusFilter(s ? 'out_of_stock' : null),
          ),
          const SizedBox(width: 6),
          ...categories.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _StyledChip(
                label: c.name,
                selected: provider.categoryId == c.id,
                color: AppColors.primary,
                onSelected: (s) => provider.setCategoryId(s ? c.id : null),
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 6),
            ActionChip(
              label: const Text('Atur Ulang'),
              avatar: const Icon(Icons.close, size: 14),
              onPressed: provider.clearFilters,
            ),
          ],
        ],
      ),
    );
  }
}

class _StyledChip extends StatelessWidget {
  const _StyledChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final Color color;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.60)
                : Theme.of(context).colorScheme.outline,
            width: selected ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && selected) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.scrollController,
    required this.isGridView,
  });

  final InventoryProvider provider;
  final ScrollController scrollController;
  final bool isGridView;

  @override
  Widget build(BuildContext context) {
    if (provider.state == InventoryListState.loading) {
      return SkeletonList(isGrid: isGridView);
    }

    if (provider.state == InventoryListState.error && provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Gagal memuat inventaris',
        message: provider.errorMessage,
        tone: Theme.of(context).colorScheme.error,
        action: FilledButton(
          onPressed: provider.refresh,
          child: const Text('Coba Lagi'),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Tidak ada barang sesuai',
        message: 'Coba hapus filter atau gunakan kata kunci lain.',
        action: OutlinedButton.icon(
          icon: const Icon(Icons.clear_all),
          onPressed: provider.clearFilters,
          label: const Text('Atur Ulang Filter'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: isGridView
          ? _GridList(provider: provider, scrollController: scrollController)
          : _ListView(provider: provider, scrollController: scrollController),
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.provider, required this.scrollController});
  final InventoryProvider provider;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
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
        final card = InventoryCard(
          inventory: inventory,
          onTap: () => _openDetail(context, inventory),
        );
        if (index >= 8) return card;
        return TweenAnimationBuilder<double>(
          key: ValueKey('inv-list-${inventory.id}'),
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + index * 35),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 10),
              child: child,
            ),
          ),
          child: card,
        );
      },
    );
  }

  void _openDetail(BuildContext context, Inventory inventory) {
    Navigator.of(
      context,
    ).pushNamed(AppRouter.inventoryDetail, arguments: inventory);
  }
}

class _GridList extends StatelessWidget {
  const _GridList({required this.provider, required this.scrollController});
  final InventoryProvider provider;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: provider.items.length + (provider.hasNextPage ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.items.length) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final inventory = provider.items[index];
        final card = _GridCard(
          inventory: inventory,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRouter.inventoryDetail, arguments: inventory),
        );
        if (index >= 8) return card;
        return TweenAnimationBuilder<double>(
          key: ValueKey('inv-grid-${inventory.id}'),
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 260 + index * 30),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.92 + t * 0.08, child: child),
          ),
          child: card,
        );
      },
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.inventory, required this.onTap});
  final Inventory inventory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = inventory.isAvailable;
    final tone = available
        ? AppColors.statusReturned
        : AppColors.statusRejected;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'inventory-image-${inventory.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: inventory.imageUrl == null
                        ? Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                          )
                        : Image.network(
                            inventory.imageUrl!,
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                            errorBuilder: (_, _, _) => Container(
                              color: theme.colorScheme.surfaceContainerHigh,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inventory.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              inventory.category?.name ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: tone,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
