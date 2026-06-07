import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_router.dart';
import '../../models/loan.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  /// Safe extractor for the avatar initial that never trips on a null
  /// or empty user name. Called every build so it must not throw on
  /// the brief window between logout and route replacement when
  /// `auth.user` is already null but the home/profile screens are
  /// still rebuilding.
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
        title: const Text('Profil'),
        automaticallyImplyLeading: !embeddedInShell,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Hero card
            Container(
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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
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
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (user?.nim != null)
                          Text(
                            'NIM ${user!.nim!}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        const SizedBox(height: 1),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // Loan stats mini-row — quick-read lifetime summary
            const _LoanStatsRow(),

            const SizedBox(height: 16),
            _SectionLabel(text: 'Akun'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.edit_outlined,
                    iconColor: AppColors.primary,
                    title: 'Edit Profil',
                    subtitle: 'Nama, email, kata sandi',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.profileEdit),
                  ),
                  _SettingDivider(),
                  _SettingTile(
                    icon: Icons.assignment_outlined,
                    iconColor: AppColors.statusBorrowed,
                    title: 'Peminjaman Saya',
                    subtitle: 'Riwayat & status peminjaman',
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRouter.loanHistory),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _SectionLabel(text: 'Preferensi'),
            const SizedBox(height: 8),
            const _ThemeCard(),

            const SizedBox(height: 16),
            _SectionLabel(text: 'Lainnya'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.help_outline,
                    iconColor: AppColors.info,
                    title: 'Bantuan & Dukungan',
                    subtitle: 'Cara kerja peminjaman',
                    onTap: () => _showAbout(context),
                  ),
                  _SettingDivider(),
                  _SettingTile(
                    icon: Icons.info_outline,
                    iconColor: AppColors.statusReturned,
                    title: 'Tentang Labventory',
                    subtitle: 'Versi & kredit',
                    onTap: () => _showAbout(context, about: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Labventory · Inventaris Lab Kampus',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
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

    // Navigate FIRST so the home/profile/loan widget tree is torn
    // down before AuthProvider flips `user` to null. Otherwise the
    // still-mounted screens rebuild against null and trip null-check
    // ops + multiple-Hero-tag errors during the transition.
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);

    // Now safely tear the session down. We don't await this on the
    // navigation thread; the user is already on /login.
    await auth.logout();
    loans.clearAll();
    notifs.clearAll();
  }

  void _showAbout(BuildContext context, {bool about = false}) {
    showAboutDialog(
      context: context,
      applicationName: 'Labventory',
      applicationVersion: about ? '1.0.0' : null,
      applicationLegalese:
          '© Labventory · Campus laboratory inventory borrowing',
      children: about
          ? null
          : [
              const SizedBox(height: 8),
              const Text(
                'Browse lab inventory, submit a borrow request with your '
                'KTM, and track the status until you return the item.',
              ),
            ],
    );
  }
}

// ---------------------------------------------------------------------
// Loan stats mini row
// ---------------------------------------------------------------------

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

    // Badge logic
    final String? badgeLabel;
    final Color? badgeColor;
    if (total >= 10 && rate >= 90) {
      badgeLabel = '🏆 Mahasiswa Terpercaya';
      badgeColor = AppColors.statusPending;
    } else if (total >= 5 && rate >= 80) {
      badgeLabel = '⭐ Peminjam Aktif';
      badgeColor = AppColors.primary;
    } else if (total >= 1) {
      badgeLabel = '📦 Peminjam Baru';
      badgeColor = AppColors.statusApproved;
    } else {
      badgeLabel = null;
      badgeColor = null;
    }

    return Column(
      children: [
        // Stats grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
              width: 0.6,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StatBox(
                    value: total.toString(),
                    label: 'Total\nPeminjaman',
                    icon: Icons.history_rounded,
                    color: AppColors.primary,
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: active.toString(),
                    label: 'Sedang\nBerjalan',
                    icon: Icons.local_shipping_outlined,
                    color: AppColors.statusBorrowed,
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: returned.toString(),
                    label: 'Telah\nDikembalikan',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.statusReturned,
                    theme: theme,
                  ),
                  const SizedBox(width: 10),
                  _StatBox(
                    value: '$rate%',
                    label: 'Tingkat\nKetepatan',
                    icon: Icons.analytics_outlined,
                    color: rate >= 80
                        ? AppColors.statusReturned
                        : AppColors.statusPending,
                    theme: theme,
                  ),
                ],
              ),
              if (rejected > 0) ...[
                const SizedBox(height: 12),
                Divider(color: theme.colorScheme.outlineVariant, height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$rejected peminjaman ditolak atau dibatalkan',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Badge
        if (badgeLabel != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: badgeColor!.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: badgeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  badgeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
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

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.theme,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Section pieces
// ---------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
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

class _SettingTile extends StatelessWidget {
  const _SettingTile({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 14,
      endIndent: 14,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

// ---------------------------------------------------------------------
// Theme switcher card
// ---------------------------------------------------------------------

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = context.watch<ThemeProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(mode.icon, color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tampilan', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(mode.label, style: theme.textTheme.bodySmall),
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
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              selected: {mode.mode},
              onSelectionChanged: (s) => mode.setMode(s.first),
            ),
          ],
        ),
      ),
    );
  }
}
