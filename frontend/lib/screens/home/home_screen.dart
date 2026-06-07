import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../models/inventory.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/loan_status_chip.dart';
import '../shell/app_shell.dart';

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
      if (inv.state == InventoryListState.idle) inv.bootstrap();
      if (loans.state == LoanHistoryState.idle) loans.loadHistory();
    });
  }

  Future<void> _refresh() async {
    final inv = context.read<InventoryProvider>();
    final loans = context.read<LoanProvider>();
    final notifs = context.read<NotificationProvider>();
    await Future.wait([
      inv.refresh(),
      loans.loadHistory(refresh: true),
      notifs.refreshUnreadCount(),
    ]);
  }

  void _switchTab(int tabIndex) => AppShell.of(context)?.setIndex(tabIndex);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inv = context.watch<InventoryProvider>();
    final loans = context.watch<LoanProvider>();
    final notifs = context.watch<NotificationProvider>();
    final theme = Theme.of(context);
    final user = auth.user;

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

    // Due-soon items
    final now = DateTime.now();
    final dueSoon = loans.items.where((l) {
      if (l.status != LoanStatus.borrowed || l.returnDate == null) {
        return false;
      }
      final diff = l.returnDate!.difference(now).inDays;
      return diff >= 0 && diff <= 3;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ── Hero ──────────────────────────────────────────────
            _HeroHeader(
              userName: user.name,
              userNim: user.nim,
              unreadCount: notifs.unreadCount,
              onNotificationTap: () => _switchTab(3),
            ),

            // ── Stat strip (overlaps hero bottom) ─────────────────
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _StatStrip(
                  activeLoans: activeLoans,
                  returned: returnedCount,
                  available: availableCount,
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick actions ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: _QuickActions(onSwitchTab: _switchTab),
                  ),

                  // ── Due-soon banner ────────────────────────────
                  if (dueSoon.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _DueSoonBanner(
                        loans: dueSoon,
                        onTap: () => _switchTab(2),
                      ),
                    ),
                  ],

                  // ── Categories ────────────────────────────────
                  _SectionHeader(
                    title: 'Kategori',
                    trailingLabel: 'Semua Inventaris',
                    onTrailing: () => _switchTab(1),
                  ),
                  _CategoryStrip(
                    categories: inv.categories,
                    onTap: (c) {
                      inv.setCategoryId(c?.id);
                      _switchTab(1);
                    },
                  ),
                  const SizedBox(height: 18),

                  // ── Featured inventory ─────────────────────────
                  _SectionHeader(
                    title: 'Inventaris Unggulan',
                    trailingLabel: 'Lihat Semua',
                    onTrailing: () => _switchTab(1),
                  ),
                  _FeaturedInventory(
                    items: inv.items.take(8).toList(),
                    loading: inv.state == InventoryListState.loading,
                    onBorrow: () => _switchTab(1),
                  ),
                  const SizedBox(height: 18),

                  // ── Recent notifications ──────────────────────
                  if (notifs.items.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Notifikasi Terbaru',
                      trailingLabel: 'Lihat Semua',
                      onTrailing: () => _switchTab(3),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _RecentNotifications(
                        notifications: notifs.items.take(3).toList(),
                        onSeeAll: () => _switchTab(3),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Recent activity ───────────────────────────
                  _SectionHeader(
                    title: 'Aktivitas Terbaru',
                    trailingLabel: loans.items.isEmpty ? null : 'Lihat Semua',
                    onTrailing: loans.items.isEmpty
                        ? null
                        : () => _switchTab(2),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero header — animated blobs + staggered entrance
// ─────────────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatefulWidget {
  const _HeroHeader({
    required this.userName,
    required this.userNim,
    required this.unreadCount,
    required this.onNotificationTap,
  });

  final String userName;
  final String? userNim;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with TickerProviderStateMixin {
  late final AnimationController _blobCtrl;
  late final AnimationController _entranceCtrl;

  // Entrance animations
  late final Animation<double> _greetingFade;
  late final Animation<Offset> _greetingSlide;
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nimFade;
  late final Animation<Offset> _nimSlide;
  late final Animation<double> _dateRowFade;

  @override
  void initState() {
    super.initState();

    // Blob rotation — 30 s continuous loop
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Entrance — 600 ms total
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    // date row — delay 0ms
    _dateRowFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    // greeting — delay 0ms
    _greetingFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
    );
    _greetingSlide =
        Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.0, 0.60, curve: Curves.easeOut),
          ),
        );

    // name — delay ~100ms (start 0.14)
    _nameFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.14, 0.72, curve: Curves.easeOut),
    );
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.14, 0.72, curve: Curves.easeOut),
          ),
        );

    // NIM — delay ~200ms (start 0.28)
    _nimFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.28, 0.85, curve: Curves.easeOut),
    );
    _nimSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.28, 0.85, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void dispose() {
    _blobCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi,';
    if (h < 15) return 'Selamat Siang,';
    if (h < 19) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  static String _displayName(String full) {
    final trimmed = full.trim();
    if (trimmed.isEmpty) return 'Pengguna';
    return trimmed
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final mqTop = MediaQuery.of(context).padding.top;
    final greeting = _greeting();
    final dateLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final displayName = _displayName(widget.userName);

    return Container(
      padding: EdgeInsets.fromLTRB(22, mqTop + 20, 22, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Animated background blobs
          Positioned(
            right: -50,
            top: -10,
            child: AnimatedBuilder(
              animation: _blobCtrl,
              builder: (context, child) {
                final angle = _blobCtrl.value * 2 * math.pi;
                final dy = math.sin(angle) * 12;
                final dx = math.cos(angle * 0.7) * 8;
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: RotationTransition(turns: _blobCtrl, child: child),
                );
              },
              child: _Blob(size: 150, color: AppColors.heroBlobA),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -20,
            child: AnimatedBuilder(
              animation: _blobCtrl,
              builder: (context, child) {
                final angle = _blobCtrl.value * 2 * math.pi;
                final dy = math.sin(angle + math.pi) * 10;
                final dx = math.cos(angle * 0.5 + math.pi) * 6;
                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: RotationTransition(
                    // counter-clockwise: negate turns via ReverseAnimation
                    turns: ReverseAnimation(_blobCtrl),
                    child: child,
                  ),
                );
              },
              child: _Blob(size: 130, color: AppColors.heroBlobB),
            ),
          ),

          // Shimmer diagonal line (CustomPainter)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
              child: CustomPaint(painter: _ShimmerDiagonalPainter()),
            ),
          ),

          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + notification bell
              FadeTransition(
                opacity: _dateRowFade,
                child: Row(
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
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onNotificationTap,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Badge(
                          isLabelVisible: widget.unreadCount > 0,
                          label: Text(
                            widget.unreadCount > 9
                                ? '9+'
                                : '${widget.unreadCount}',
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Greeting
              FadeTransition(
                opacity: _greetingFade,
                child: SlideTransition(
                  position: _greetingSlide,
                  child: Text(
                    greeting,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),

              // Name
              FadeTransition(
                opacity: _nameFade,
                child: SlideTransition(
                  position: _nameSlide,
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // NIM badge
              if (widget.userNim != null)
                FadeTransition(
                  opacity: _nimFade,
                  child: SlideTransition(
                    position: _nimSlide,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              color: Colors.white70,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.userNim!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Subtle shimmer diagonal line across the hero gradient.
class _ShimmerDiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.07),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.35, 0.50, 0.65],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerDiagonalPainter oldDelegate) => false;
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
        color: color.withValues(alpha: 0.28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat strip — animated slide-up on load + counting numbers
// ─────────────────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 40.0, end: 0.0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.elasticOut,
      builder: (context, offsetY, child) {
        return Transform.translate(offset: Offset(0, offsetY), child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            _StatTile(
              icon: Icons.pending_actions_rounded,
              tone: AppColors.statusPending,
              label: 'Aktif',
              value: activeLoans,
            ),
            _StatDivider(),
            _StatTile(
              icon: Icons.check_circle_outline_rounded,
              tone: AppColors.statusReturned,
              label: 'Dikembalikan',
              value: returned,
            ),
            _StatDivider(),
            _StatTile(
              icon: Icons.inventory_2_outlined,
              tone: AppColors.primary,
              label: 'Tersedia',
              value: available,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatefulWidget {
  const _StatTile({
    required this.icon,
    required this.tone,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color tone;
  final String label;
  final int value;

  @override
  State<_StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<_StatTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.tone, size: 18),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, animatedValue, _) {
              return Text(
                '$animatedValue',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              );
            },
          ),
          const SizedBox(height: 1),
          Text(
            widget.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions — staggered entrance + scale-on-press
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActions extends StatefulWidget {
  const _QuickActions({required this.onSwitchTab});
  final void Function(int) onSwitchTab;

  @override
  State<_QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<_QuickActions>
    with TickerProviderStateMixin {
  static const _delays = [0, 80, 160, 240];

  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _fades;
  late final List<Animation<Offset>> _slides;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(4, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      );
    });
    _fades = _ctrls
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _slides = _ctrls
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)),
        )
        .toList();

    for (var i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) _ctrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = [
      _QA(
        icon: Icons.inventory_2_outlined,
        label: 'Inventaris',
        color: AppColors.primary,
        onTap: () => widget.onSwitchTab(1),
      ),
      _QA(
        icon: Icons.history_rounded,
        label: 'Riwayat',
        color: AppColors.statusReturned,
        onTap: () => widget.onSwitchTab(2),
      ),
      _QA(
        icon: Icons.notifications_outlined,
        label: 'Notifikasi',
        color: AppColors.statusApproved,
        onTap: () => widget.onSwitchTab(3),
      ),
      _QA(
        icon: Icons.person,
        label: 'Profil',
        color: AppColors.accent,
        onTap: () => widget.onSwitchTab(4),
      ),
    ];

    return Row(
      children: List.generate(actions.length, (i) {
        final qa = actions[i];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FadeTransition(
              opacity: _fades[i],
              child: SlideTransition(
                position: _slides[i],
                child: _QuickActionTile(
                  icon: qa.icon,
                  label: qa.label,
                  color: qa.color,
                  onTap: qa.onTap,
                  theme: theme,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _QA {
  const _QA({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.theme,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.93),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.theme.colorScheme.outlineVariant,
                width: 0.6,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Colored top accent stripe
                Container(
                  height: 3,
                  color: widget.color.withValues(alpha: 0.55),
                ),
                // Icon + label
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 11, 4, 13),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 21),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.label,
                        style: widget.theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                          letterSpacing: 0.1,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
// ─────────────────────────────────────────────────────────────────────────────
// Section header — animated accent bar + slide-in
// ─────────────────────────────────────────────────────────────────────────────

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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(opacity: t, child: child);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 8, 8),
        child: Row(
          children: [
            // Left accent bar — animates height from 0 to 16
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 16.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, h, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    width: 3,
                    height: h,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (trailingLabel != null && onTrailing != null)
              TextButton(
                onPressed: onTrailing,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trailingLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category strip — staggered horizontal entrance from left
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.categories, required this.onTap});

  final List<dynamic> categories;
  final void Function(dynamic) onTap;

  static const _palette = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.statusPending,
    AppColors.statusReturned,
    AppColors.statusBorrowed,
  ];
  static const _icons = [
    Icons.memory_outlined,
    Icons.camera_alt_outlined,
    Icons.router_outlined,
    Icons.sensors_outlined,
    Icons.handyman_outlined,
    Icons.cast_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox(height: 4);

    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final color = _palette[i % _palette.length];
          final icon = _icons[i % _icons.length];
          // Staggered slide from left (offset X from +20 to 0)
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 350 + i * 60),
            curve: Curves.easeOut,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(20 * (1 - t), 0),
                  child: child,
                ),
              );
            },
            child: _CategoryTile(
              label: c.name as String,
              icon: icon,
              color: color,
              onTap: () => onTap(c),
            ),
          );
        },
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
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.6,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with colored bottom gradient strip
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 21),
                    ),
                    // Colored bottom gradient strip
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.withValues(alpha: 0.0),
                              color.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 10.5,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured inventory horizontal scroll — staggered scale+fade entrance
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedInventory extends StatelessWidget {
  const _FeaturedInventory({
    required this.items,
    required this.loading,
    required this.onBorrow,
  });

  final List<Inventory> items;
  final bool loading;
  final VoidCallback onBorrow;

  static const double _cardW = 195;
  static const double _cardH = 238;
  static const double _imgH = 124;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading && items.isEmpty) {
      return SizedBox(
        height: _cardH,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => _SkeletonCard(theme: theme, width: _cardW),
        ),
      );
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _EmptyInventoryCard(theme: theme, onBrowse: onBorrow),
      );
    }

    return SizedBox(
      height: _cardH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final item = items[i];
          // Staggered scale 0.92→1.0 + fade, delay i*50ms
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + i * 50),
            curve: Curves.easeOut,
            builder: (context, t, child) {
              final scale = 0.92 + 0.08 * t;
              return Opacity(
                opacity: t,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: SizedBox(
              width: _cardW,
              child: _FeaturedCard(item: item, imageHeight: _imgH),
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.theme, required this.width});
  final ThemeData theme;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _EmptyInventoryCard extends StatelessWidget {
  const _EmptyInventoryCard({required this.theme, required this.onBrowse});
  final ThemeData theme;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.6),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: theme.colorScheme.onSurfaceVariant,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text('Belum ada inventaris', style: theme.textTheme.bodyMedium),
        ],
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
    final statusColor = available
        ? AppColors.statusReturned
        : AppColors.statusRejected;
    // Availability indicator line color: green if available, red if not
    final indicatorColor = available ? AppColors.success : AppColors.danger;

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
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.6,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image with top availability indicator line
              Stack(
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
                                  size: 34,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                memCacheWidth: 600,
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
                  ),
                  // 2px colored availability indicator at top edge
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Container(height: 2, color: indicatorColor),
                    ),
                  ),
                ],
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
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
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.category?.name ?? item.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              available ? 'Tersedia' : 'Habis',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '×${item.stock}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
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

// ─────────────────────────────────────────────────────────────────────────────
// Recent activity — slide-up fade entrance
// ─────────────────────────────────────────────────────────────────────────────

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
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.6,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (loans.isEmpty) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - t)),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.6,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: theme.colorScheme.onSurfaceVariant,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'Belum ada peminjaman',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih alat dari inventaris dan mulai pinjam.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton.tonal(
                onPressed: onEmptyAction,
                child: const Text('Jelajahi Inventaris'),
              ),
            ],
          ),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.6,
          ),
        ),
        child: Column(
          children: [
            for (var i = 0; i < loans.length; i++) ...[
              _LoanRow(loan: loans[i]),
              if (i < loans.length - 1)
                Divider(
                  height: 1,
                  indent: 66,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
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
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
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
                    loan.inventory?.name ?? 'Peminjaman #${loan.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _periodLabel(loan),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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

  static String _periodLabel(Loan loan) {
    final df = DateFormat('d MMM');
    if (loan.borrowDate != null && loan.returnDate != null) {
      return '${df.format(loan.borrowDate!)} → ${df.format(loan.returnDate!)}';
    }
    return loan.createdAt == null
        ? '—'
        : DateFormat('d MMM, HH:mm').format(loan.createdAt!.toLocal());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Due-soon banner
// ─────────────────────────────────────────────────────────────────────────────

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
    final accent = urgent ? AppColors.danger : AppColors.statusPending;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.30), width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                urgent
                    ? Icons.warning_amber_rounded
                    : Icons.access_time_rounded,
                color: accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    urgent
                        ? 'Harus dikembalikan HARI INI'
                        : 'Kembalikan dalam $daysLeft hari',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    first.inventory?.name ?? 'Peminjaman #${first.id}',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (loans.length > 1)
                    Text(
                      '+ ${loans.length - 1} lainnya',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent notifications mini-strip — slide-up entrance
// ─────────────────────────────────────────────────────────────────────────────

class _RecentNotifications extends StatelessWidget {
  const _RecentNotifications({
    required this.notifications,
    required this.onSeeAll,
  });

  final List<AppNotification> notifications;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 0.6,
          ),
        ),
        child: Column(
          children: [
            for (var i = 0; i < notifications.length; i++) ...[
              _NotifRow(notif: notifications[i], onTap: onSeeAll),
              if (i < notifications.length - 1)
                Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.notif, required this.onTap});
  final AppNotification notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _meta(notif.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: meta.$1.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.$2, color: meta.$1, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: notif.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  Text(
                    _relTime(notif.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: meta.$1,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  static (Color, IconData) _meta(String type) {
    return switch (type) {
      AppNotification.typeLoanCreated => (
        AppColors.statusPending,
        Icons.pending_actions_rounded,
      ),
      AppNotification.typeLoanApproved => (
        AppColors.statusApproved,
        Icons.check_circle_rounded,
      ),
      AppNotification.typeLoanRejected => (
        AppColors.statusRejected,
        Icons.cancel_rounded,
      ),
      AppNotification.typeLoanBorrowed => (
        AppColors.statusBorrowed,
        Icons.outbox_rounded,
      ),
      AppNotification.typeLoanReturned => (
        AppColors.statusReturned,
        Icons.move_to_inbox_rounded,
      ),
      _ => (AppColors.info, Icons.notifications_rounded),
    };
  }

  static String _relTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${(diff.inDays / 7).floor()}mg lalu';
  }
}
