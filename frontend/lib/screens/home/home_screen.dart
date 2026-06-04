import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/inventory.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/loan_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/loan_status_chip.dart';
import '../shell/app_shell.dart';

/// Post-login landing screen: time-aware greeting, quick stats, hero
/// gradient header, category shortcuts, featured inventory, and recent
/// loan activity.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bootstrapped) return;
      _bootstrapped = true;
      final inv = context.read<InventoryProvider>();
      final loans = context.read<LoanProvider>();
      if (inv.state == InventoryListState.idle) {
        inv.bootstrap();
      }
      if (loans.state == LoanHistoryState.idle) {
        loans.loadHistory();
      }
    });
  }

  Future<void> _refresh() async {
    final inv = context.read<InventoryProvider>();
    final loans = context.read<LoanProvider>();
    await Future.wait([inv.refresh(), loans.loadHistory(refresh: true)]);
  }

  void _switchTab(int tabIndex) {
    AppShell.of(context)?.setIndex(tabIndex);
  }

  List<Widget> _buildDueSoonBanner(List<Loan> loans, ThemeData theme) {
    final now = DateTime.now();
    final dueSoon = loans.where((l) {
      if (l.status != LoanStatus.borrowed) return false;
      if (l.returnDate == null) return false;
      final diff = l.returnDate!.difference(now).inDays;
      return diff >= 0 && diff <= 3;
    }).toList();

    if (dueSoon.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: _DueSoonBanner(loans: dueSoon, onTap: () => _switchTab(2)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inv = context.watch<InventoryProvider>();
    final loans = context.watch<LoanProvider>();
    final theme = Theme.of(context);
    final user = auth.user;

    // During logout this screen briefly rebuilds with `user == null`
    // before the route is replaced. Render an empty placeholder so we
    // don't trip null-check ops on accessors below.
    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const SizedBox.shrink(),
      );
    }

    final activeLoans = loans.items
        .where(
          (l) =>
              l.status == LoanStatus.pending ||
              l.status == LoanStatus.approved ||
              l.status == LoanStatus.borrowed,
        )
        .length;
    final returnedCount = loans.items
        .where((l) => l.status == LoanStatus.returned)
        .length;
    final availableCount = inv.items.where((i) => i.isAvailable).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Extend behind status bar so the gradient hero meets the top
      // edge cleanly. SafeArea is applied selectively below.
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HeroHeader(userName: user.name, userNim: user.nim),
            // Stat strip overlaps the bottom edge of the hero by a
            // small amount so the rounded gradient meets the card
            // visually but the strip's content stays comfortably
            // inside the page area below.
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _StatStrip(
                  activeLoans: activeLoans,
                  returned: returnedCount,
                  available: availableCount,
                ),
              ),
            ),
            // Pull the rest of the page up by an equal amount so the
            // stat strip transition isn't followed by a phantom gap.
            Transform.translate(
              offset: const Offset(0, -16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick action pills
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _QuickActions(onSwitchTab: _switchTab),
                  ),

                  // "Due soon" alert banner — only shown when user has
                  // borrowed items with return date within 3 days.
                  ..._buildDueSoonBanner(loans.items, theme),

                  _SectionHeader(
                    title: 'Browse by category',
                    trailingLabel: 'See all',
                    onTrailing: () => _switchTab(1),
                  ),
                  _CategoryStrip(
                    categories: inv.categories,
                    onTap: (c) {
                      inv.setCategoryId(c?.id);
                      _switchTab(1);
                    },
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Featured inventory',
                    trailingLabel: 'See all',
                    onTrailing: () => _switchTab(1),
                  ),
                  _FeaturedInventory(
                    items: inv.items.take(8).toList(),
                    loading: inv.state == InventoryListState.loading,
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Recent activity',
                    trailingLabel: loans.items.isEmpty ? null : 'See all',
                    onTrailing: loans.items.isEmpty
                        ? null
                        : () => _switchTab(2),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _RecentActivity(
                      loans: loans.items.take(4).toList(),
                      loading: loans.state == LoanHistoryState.loading,
                      onEmptyAction: () => _switchTab(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.userName, required this.userNim});

  final String userName;
  final String? userNim;

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting();
    final dateLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final mqTop = MediaQuery.of(context).padding.top;
    final displayName = _displayName(userName);

    return Container(
      // Slimmer hero: top breathing room (mqTop + 24) plus a smaller
      // bottom pad (52) since the stat strip overlaps from below.
      // Horizontal padding kept at 22 — generous enough for the rounded
      // corners but no longer wasting horizontal real estate.
      padding: EdgeInsets.fromLTRB(22, mqTop + 24, 22, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative blobs constrained inside the hero so they
            // never escape into the status bar area.
            Positioned(
              right: -60,
              top: 0,
              child: _Blob(size: 160, color: AppColors.heroBlobA),
            ),
            Positioned(
              left: -70,
              bottom: -20,
              child: _Blob(size: 140, color: AppColors.heroBlobB),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$greeting,',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (userNim != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'NIM $userNim',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Good morning';
    if (h < 15) return 'Good afternoon';
    if (h < 19) return 'Good evening';
    return 'Good night';
  }

  /// Title-case the user's full name for display in the hero. We keep
  /// the entire name (not just the first token) so two-word names like
  /// "fikrul hanif" don't appear truncated.
  static String _displayName(String full) {
    final trimmed = full.trim();
    if (trimmed.isEmpty) return 'there';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.32),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Stat strip
// ---------------------------------------------------------------------

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.activeLoans,
    required this.returned,
    required this.available,
  });

  final int activeLoans;
  final int returned;
  final int available;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Row(
            children: [
              _StatTile(
                icon: Icons.pending_actions,
                tone: AppColors.statusPending,
                label: 'Active',
                value: activeLoans.toString(),
              ),
              _Divider(),
              _StatTile(
                icon: Icons.check_circle_outline,
                tone: AppColors.statusReturned,
                label: 'Returned',
                value: returned.toString(),
              ),
              _Divider(),
              _StatTile(
                icon: Icons.inventory_2_outlined,
                tone: AppColors.primary,
                label: 'Available',
                value: available.toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color tone;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tone, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ---------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailingLabel,
    this.onTrailing,
  });
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailingLabel != null && onTrailing != null)
            TextButton(onPressed: onTrailing, child: Text(trailingLabel!)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Category strip
// ---------------------------------------------------------------------

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories, required this.onTap});

  final List<dynamic> categories;
  final void Function(dynamic) onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox(height: 8);
    }

    final palette = const [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.statusPending,
      AppColors.statusReturned,
      AppColors.statusBorrowed,
    ];
    final icons = const [
      Icons.memory_outlined,
      Icons.camera_alt_outlined,
      Icons.router_outlined,
      Icons.sensors_outlined,
      Icons.handyman_outlined,
      Icons.cast_outlined,
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        itemBuilder: (context, i) {
          final c = categories[i];
          final color = palette[i % palette.length];
          final icon = icons[i % icons.length];
          return _CategoryTile(
            label: c.name as String,
            icon: icon,
            color: color,
            onTap: () => onTap(c),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemCount: categories.length,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline, width: 0.6),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Featured inventory (horizontal cards)
// ---------------------------------------------------------------------

class _FeaturedInventory extends StatelessWidget {
  const _FeaturedInventory({required this.items, required this.loading});

  final List<Inventory> items;
  final bool loading;

  // Single fixed dimensions so child cards never overflow. Width slim
  // enough that two cards peek on a 6" screen.
  static const double _cardWidth = 200;
  static const double _cardHeight = 240;
  static const double _imageHeight = 130;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading && items.isEmpty) {
      return SizedBox(
        height: _cardHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemBuilder: (context, _) => SizedBox(
            width: _cardWidth,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemCount: 4,
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline, width: 0.6),
          ),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 40,
              ),
              const SizedBox(height: 8),
              Text('No inventory yet.', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: _cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: _cardWidth,
            child: _FeaturedCard(item: item, imageHeight: _imageHeight),
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemCount: items.length,
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.imageHeight});
  final Inventory item;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = item.isAvailable;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRouter.inventoryDetail, arguments: item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outline, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'featured-inventory-image-${item.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: imageHeight,
                    width: double.infinity,
                    child: item.imageUrl == null
                        ? Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 36,
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            // Request a sensibly sized cache entry to
                            // sidestep the "burik" low-res rendering
                            // when CachedNetworkImage uses tiny default
                            // intrinsic dimensions.
                            memCacheWidth: 600,
                            placeholder: (context, _) => Container(
                              color: theme.colorScheme.surfaceContainerHigh,
                            ),
                            errorWidget: (context, _, _) => Container(
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
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _Pill(
                            color: available
                                ? AppColors.statusReturned
                                : AppColors.statusRejected,
                            label: available ? 'Available' : 'Out',
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'x${item.stock}',
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
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Recent activity
// ---------------------------------------------------------------------

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({
    required this.loans,
    required this.loading,
    required this.onEmptyAction,
  });
  final List<Loan> loans;
  final bool loading;
  final VoidCallback onEmptyAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading && loans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    if (loans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                'No loans yet',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Pick an item from the inventory to submit your first loan.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: onEmptyAction,
                child: const Text('Browse inventory'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < loans.length; i++) ...[
            _LoanRow(loan: loans[i]),
            if (i < loans.length - 1)
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ],
        ],
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
    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRouter.loanDetail, arguments: loan.id),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loan.inventory?.name ?? 'Loan #${loan.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(_periodLabel(loan), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            LoanStatusChip(status: loan.status, compact: true),
          ],
        ),
      ),
    );
  }

  String _periodLabel(Loan loan) {
    final df = DateFormat('d MMM');
    if (loan.borrowDate != null && loan.returnDate != null) {
      return '${df.format(loan.borrowDate!)} → ${df.format(loan.returnDate!)}';
    }
    return loan.createdAt == null
        ? '—'
        : DateFormat('d MMM, HH:mm').format(loan.createdAt!.toLocal());
  }
}

// ---------------------------------------------------------------------
// Quick actions row
// ---------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onSwitchTab});
  final void Function(int) onSwitchTab;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.inventory_2_outlined,
        label: 'Browse',
        color: AppColors.primary,
        tab: 1,
      ),
      (
        icon: Icons.add_circle_outline,
        label: 'Borrow',
        color: AppColors.accent,
        tab: 1,
      ),
      (
        icon: Icons.assignment_outlined,
        label: 'My loans',
        color: AppColors.statusBorrowed,
        tab: 2,
      ),
      (
        icon: Icons.person_outline,
        label: 'Profile',
        color: AppColors.statusReturned,
        tab: 3,
      ),
    ];
    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: _QuickActionTile(
                icon: item.icon,
                label: item.label,
                color: item.color,
                onTap: () => onSwitchTab(item.tab),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline, width: 0.6),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Due soon warning banner
// ---------------------------------------------------------------------

class _DueSoonBanner extends StatelessWidget {
  const _DueSoonBanner({required this.loans, required this.onTap});
  final List<Loan> loans;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = loans.first;
    final now = DateTime.now();
    final daysLeft = first.returnDate?.difference(now).inDays ?? 0;
    final urgent = daysLeft <= 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: urgent
              ? AppColors.danger.withValues(alpha: 0.10)
              : AppColors.statusPending.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: urgent
                ? AppColors.danger.withValues(alpha: 0.35)
                : AppColors.statusPending.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              urgent ? Icons.warning_amber_rounded : Icons.access_time_rounded,
              color: urgent ? AppColors.danger : AppColors.statusPending,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urgent
                        ? 'Return due TODAY'
                        : 'Return due in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: urgent
                          ? AppColors.danger
                          : AppColors.statusPending,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    first.inventory?.name ?? 'Loan #${first.id}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (loans.length > 1)
                    Text(
                      'and ${loans.length - 1} more',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
