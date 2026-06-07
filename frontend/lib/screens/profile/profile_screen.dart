import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/loan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  static String _firstChar(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final user = auth.user;
    final initial = _firstChar(user?.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: !embeddedInShell,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          // ── Hero card ───────────────────────────────────────────
          _HeroCard(initial: initial, user: user),
          const SizedBox(height: 14),

          // ── Stat + badge ────────────────────────────────────────
          const _LoanStatsRow(),
          const SizedBox(height: 20),

          // ── Akun ────────────────────────────────────────────────
          _SectionLabel(text: 'Akun'),
          const SizedBox(height: 8),
          _MenuCard(
            items: [
              _MenuItem(
                icon: Icons.edit_outlined,
                iconColor: AppColors.primary,
                title: 'Edit Profil',
                subtitle: 'Nama, email, kata sandi',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.profileEdit),
              ),
              _MenuItem(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.statusBorrowed,
                title: 'Peminjaman Saya',
                subtitle: 'Riwayat & status peminjaman',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.loanHistory),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                iconColor: AppColors.statusApproved,
                title: 'Notifikasi',
                subtitle: 'Riwayat notifikasi peminjaman',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRouter.notifications),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Preferensi ───────────────────────────────────────────
          _SectionLabel(text: 'Preferensi'),
          const SizedBox(height: 8),
          const _ThemeCard(),
          const SizedBox(height: 16),

          // ── Panduan & Informasi ──────────────────────────────────
          _SectionLabel(text: 'Panduan & Informasi'),
          const SizedBox(height: 8),
          _MenuCard(
            items: [
              _MenuItem(
                icon: Icons.map_outlined,
                iconColor: AppColors.accent,
                title: 'Panduan Peminjaman',
                subtitle: 'Langkah-langkah meminjam alat',
                onTap: () => _showGuide(context),
              ),
              _MenuItem(
                icon: Icons.help_outline,
                iconColor: AppColors.info,
                title: 'Bantuan & Dukungan',
                subtitle: 'FAQ dan cara kerja sistem',
                onTap: () => _showHelp(context),
              ),
              _MenuItem(
                icon: Icons.info_outline,
                iconColor: AppColors.statusReturned,
                title: 'Tentang Labventory',
                subtitle: 'Versi 1.0.0',
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Keluar ───────────────────────────────────────────────
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout),
            label: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Labventory v1.0.0 · Sistem Inventaris Lab',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────

  Future<void> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar?'),
        content: const Text(
          'Anda perlu masuk kembali untuk mengakses aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final auth = context.read<AuthProvider>();
    final loans = context.read<LoanProvider>();
    final notifs = context.read<NotificationProvider>();

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);

    await auth.logout();
    loans.clearAll();
    notifs.clearAll();
  }

  void _showGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GuideBottomSheet(),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HelpBottomSheet(),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AboutBottomSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.initial, required this.user});
  final String initial;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientStart.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.40),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                if (user?.nim != null)
                  _InfoPill(icon: Icons.badge_outlined, label: user!.nim!),
                const SizedBox(height: 4),
                _InfoPill(
                  icon: Icons.alternate_email,
                  label: user?.email ?? '',
                  maxLength: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.maxLength});
  final IconData icon;
  final String label;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final display = maxLength != null && label.length > maxLength!
        ? '${label.substring(0, maxLength!)}…'
        : label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 12),
        const SizedBox(width: 4),
        Text(
          display,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loan stats — fixed overflow by using 2-column grid layout
// ─────────────────────────────────────────────────────────────────────────────

class _LoanStatsRow extends StatelessWidget {
  const _LoanStatsRow();

  @override
  Widget build(BuildContext context) {
    final loans = context.watch<LoanProvider>().items;
    final theme = Theme.of(context);

    final total = loans.length;
    final returned = loans.where((l) => l.status == LoanStatus.returned).length;
    final active = loans
        .where(
          (l) =>
              l.status == LoanStatus.pending ||
              l.status == LoanStatus.approved ||
              l.status == LoanStatus.borrowed,
        )
        .length;
    final rejected = loans.where((l) => l.status == LoanStatus.rejected).length;
    final rate = total == 0 ? 0 : ((returned / total) * 100).round();

    // Badge
    final badge = total == 0
        ? null
        : total >= 10 && rate >= 90
        ? (
            icon: Icons.military_tech_rounded,
            label: 'Mahasiswa Terpercaya',
            color: AppColors.statusPending,
          )
        : total >= 5 && rate >= 80
        ? (
            icon: Icons.star_rounded,
            label: 'Peminjam Aktif',
            color: AppColors.primary,
          )
        : (
            icon: Icons.emoji_events_outlined,
            label: 'Peminjam Baru',
            color: AppColors.statusApproved,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2×2 stat grid — prevents the overflow on narrow labels
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _StatTile(
              value: '$total',
              label: 'Total Pinjaman',
              icon: Icons.history_rounded,
              color: AppColors.primary,
            ),
            _StatTile(
              value: '$active',
              label: 'Sedang Aktif',
              icon: Icons.local_shipping_outlined,
              color: AppColors.statusBorrowed,
            ),
            _StatTile(
              value: '$returned',
              label: 'Dikembalikan',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.statusReturned,
            ),
            _StatTile(
              value: '$rate%',
              label: 'Pengembalian',
              icon: Icons.analytics_outlined,
              color: rate >= 80
                  ? AppColors.statusReturned
                  : AppColors.statusPending,
            ),
          ],
        ),

        // Rejection note
        if (rejected > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '$rejected peminjaman ditolak atau dibatalkan',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Badge pill
        if (badge != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              color: badge.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: badge.color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(badge.icon, size: 18, color: badge.color),
                const SizedBox(width: 8),
                Text(
                  badge.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: badge.color,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  final String value, label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu card
// ─────────────────────────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.6),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuTile(
              item: items[i],
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  const _MenuTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });
  final _MenuItem item;
  final bool isFirst, isLast;

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;

    final radius = BorderRadius.vertical(
      top: widget.isFirst ? const Radius.circular(17) : Radius.zero,
      bottom: widget.isLast ? const Radius.circular(17) : Radius.zero,
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        item.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.iconColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
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
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Theme card
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = context.watch<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.6),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(mode.icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tampilan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mode.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined, size: 17),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto, size: 17),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined, size: 17),
              ),
            ],
            selected: {mode.mode},
            onSelectionChanged: (s) => mode.setMode(s.first),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheets — Guide, Help, About
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSheetBase extends StatelessWidget {
  const _BottomSheetBase({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(child: child),
        ],
      ),
    );
  }
}

// ── Panduan Peminjaman ────────────────────────────────────────────────────────

class _GuideBottomSheet extends StatelessWidget {
  const _GuideBottomSheet();

  static const _steps = [
    (
      icon: Icons.search_rounded,
      color: AppColors.primary,
      title: 'Temukan Inventaris',
      desc:
          'Buka menu Inventaris, cari alat berdasarkan nama, kode, atau kategori. Cek ketersediaan stok sebelum mengajukan.',
    ),
    (
      icon: Icons.assignment_add,
      color: AppColors.statusApproved,
      title: 'Ajukan Peminjaman',
      desc:
          'Buka detail alat lalu tekan "Pinjam". Isi tanggal pinjam, tanggal kembali, dan unggah foto KTM sebagai dokumen pendukung.',
    ),
    (
      icon: Icons.hourglass_top_rounded,
      color: AppColors.statusPending,
      title: 'Tunggu Persetujuan',
      desc:
          'Laboran akan meninjau pengajuan Anda. Anda akan mendapat notifikasi saat status berubah — bisa disetujui atau ditolak.',
    ),
    (
      icon: Icons.local_shipping_outlined,
      color: AppColors.statusBorrowed,
      title: 'Ambil Inventaris',
      desc:
          'Setelah disetujui, datang ke laboratorium dan temui laboran. Laboran akan memindai QR atau memproses serah terima.',
    ),
    (
      icon: Icons.move_to_inbox_rounded,
      color: AppColors.statusReturned,
      title: 'Kembalikan Tepat Waktu',
      desc:
          'Kembalikan alat sesuai tanggal yang disepakati. Laboran akan mencatat pengembalian. Status akan berubah menjadi "Dikembalikan".',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BottomSheetBase(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Panduan Peminjaman',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '5 langkah mudah meminjam alat lab',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 16),

          // Steps
          for (var i = 0; i < _steps.length; i++) ...[
            _GuideStep(
              step: i + 1,
              icon: _steps[i].icon,
              color: _steps[i].color,
              title: _steps[i].title,
              desc: _steps[i].desc,
              isLast: i == _steps.length - 1,
            ),
          ],

          // Tip box
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pastikan KTM Anda terlihat jelas saat difoto. Pengajuan tanpa KTM yang valid akan ditolak laboran.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.isLast,
  });
  final int step;
  final IconData icon;
  final Color color;
  final String title, desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Langkah $step',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bantuan & FAQ ─────────────────────────────────────────────────────────────

class _HelpBottomSheet extends StatelessWidget {
  const _HelpBottomSheet();

  static const _faqs = [
    (
      q: 'Berapa lama proses persetujuan peminjaman?',
      a: 'Laboran biasanya meninjau dalam 1 hari kerja. Anda akan mendapat notifikasi saat status berubah.',
    ),
    (
      q: 'Apakah saya bisa meminjam lebih dari satu alat sekaligus?',
      a: 'Ya. Anda dapat mengajukan peminjaman untuk beberapa alat secara terpisah. Setiap alat memiliki nomor peminjaman sendiri.',
    ),
    (
      q: 'Apa yang terjadi jika peminjaman saya ditolak?',
      a: 'Laboran akan mencantumkan alasan penolakan. Anda bisa melihatnya di halaman detail peminjaman dan mengajukan kembali.',
    ),
    (
      q: 'Bagaimana jika saya tidak bisa mengembalikan tepat waktu?',
      a: 'Segera hubungi laboran sebelum tanggal pengembalian. Pengembalian terlambat dapat mempengaruhi pengajuan berikutnya.',
    ),
    (
      q: 'Apakah KTM wajib diunggah?',
      a: 'Ya. KTM adalah dokumen identitas wajib untuk setiap pengajuan peminjaman sebagai bukti mahasiswa aktif.',
    ),
    (
      q: 'Apakah saya bisa membatalkan peminjaman?',
      a: 'Ya, selama status masih "Menunggu". Buka detail peminjaman dan tekan "Batalkan Peminjaman" di bagian bawah halaman.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BottomSheetBase(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: AppColors.info,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bantuan & Dukungan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Pertanyaan yang sering diajukan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 12),
          for (final faq in _faqs) ...[
            _FaqTile(question: faq.q, answer: faq.a),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question, answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _open
            ? AppColors.primary.withValues(alpha: 0.05)
            : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _open
              ? AppColors.primary.withValues(alpha: 0.25)
              : theme.colorScheme.outlineVariant,
          width: _open ? 1.0 : 0.6,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _open ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _open
                          ? AppColors.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ),
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tentang Labventory ────────────────────────────────────────────────────────

class _AboutBottomSheet extends StatelessWidget {
  const _AboutBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _BottomSheetBase(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // App icon
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                'assets/app_icon.png',
                width: 88,
                height: 88,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Labventory',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sistem Peminjaman Inventaris Laboratorium',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Version pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Versi 1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 12),
            _AboutRow(
              icon: Icons.school_outlined,
              text: 'Dikembangkan untuk kampus',
            ),
            const SizedBox(height: 8),
            _AboutRow(
              icon: Icons.devices_outlined,
              text: 'Flutter + Laravel · MySQL',
            ),
            const SizedBox(height: 8),
            _AboutRow(
              icon: Icons.copyright_outlined,
              text: '© 2026 Labventory',
            ),
            const SizedBox(height: 20),
            // Licenses button — opens the standard Flutter licenses page
            OutlinedButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Labventory',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Labventory',
                applicationIcon: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/app_icon.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.article_outlined, size: 18),
              label: const Text('Lihat Lisensi Open-Source'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
