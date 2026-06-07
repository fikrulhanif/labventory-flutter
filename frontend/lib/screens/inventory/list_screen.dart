import 'package:cached_network_image/cached_network_image.dart';
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
  late final AnimationController _headerCtrl;

  @override
  void initState() {
    super.initState();
    _viewToggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

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
    _headerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: !widget.embeddedInShell,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            const Text(
              'Inventaris',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            if (provider.items.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${provider.items.length}${provider.hasNextPage ? '+' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _viewToggleCtrl,
            builder: (_, _) => IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isGridView
                      ? Icons.view_list_rounded
                      : Icons.grid_view_rounded,
                  key: ValueKey(_isGridView),
                  color: Colors.white,
                ),
              ),
              onPressed: _toggleView,
              tooltip: _isGridView ? 'Tampilan list' : 'Tampilan grid',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _headerCtrl,
              curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: AppSearchBar(
                    hint: 'Cari berdasarkan nama atau kode…',
                    initialValue: provider.search,
                    onChanged: provider.setSearch,
                    hasActiveFilter:
                        provider.categoryId != null ||
                        provider.statusFilter != null,
                  ),
                ),
                const SizedBox(height: 8),
                _FilterRow(provider: provider),
                const SizedBox(height: 4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips
// ─────────────────────────────────────────────────────────────────────────────

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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
            _ResetChip(onPressed: provider.clearFilters),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : Theme.of(context).colorScheme.outline,
            width: selected ? 1.3 : 0.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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

class _ResetChip extends StatelessWidget {
  const _ResetChip({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.30),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 13, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text(
              'Reset',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
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

// ─────────────────────────────────────────────────────────────────────────────
// List view
// ─────────────────────────────────────────────────────────────────────────────

class _ListView extends StatelessWidget {
  const _ListView({required this.provider, required this.scrollController});
  final InventoryProvider provider;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
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
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRouter.inventoryDetail, arguments: inventory),
        );
        if (index >= 10) return card;
        return TweenAnimationBuilder<double>(
          key: ValueKey('inv-list-${inventory.id}'),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid view
// ─────────────────────────────────────────────────────────────────────────────

class _GridList extends StatelessWidget {
  const _GridList({required this.provider, required this.scrollController});
  final InventoryProvider provider;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
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
        if (index >= 10) return card;
        return TweenAnimationBuilder<double>(
          key: ValueKey('inv-grid-${inventory.id}'),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 260 + index * 35),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.90 + t * 0.10, child: child),
          ),
          child: card,
        );
      },
    );
  }
}

class _GridCard extends StatefulWidget {
  const _GridCard({required this.inventory, required this.onTap});
  final Inventory inventory;
  final VoidCallback onTap;

  @override
  State<_GridCard> createState() => _GridCardState();
}

class _GridCardState extends State<_GridCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inv = widget.inventory;
    final available = inv.isAvailable;
    final tone = available
        ? AppColors.statusReturned
        : AppColors.statusRejected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with category overlay
                Stack(
                  children: [
                    Hero(
                      tag: 'inventory-image-${inv.id}',
                      child: AspectRatio(
                        aspectRatio: 1.2,
                        child: inv.imageUrl == null
                            ? Container(
                                color: tone.withValues(alpha: 0.10),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: tone.withValues(alpha: 0.50),
                                  size: 36,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: inv.imageUrl!,
                                fit: BoxFit.cover,
                                memCacheWidth: 400,
                                placeholder: (_, _) => Container(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                      ),
                    ),
                    // Top availability indicator
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 3, color: tone),
                    ),
                    // Category badge overlay (bottom of image)
                    if (inv.category != null)
                      Positioned(
                        bottom: 6,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            inv.category!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          inv.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: tone,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              available ? 'Tersedia' : 'Habis',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: tone,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '×${inv.stock}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
