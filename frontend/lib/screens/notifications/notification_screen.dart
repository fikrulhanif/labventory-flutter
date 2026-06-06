import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/notification_provider.dart';

/// Full notification center screen. Accessed via the Notifikasi tab in
/// the student shell, and from the "Lihat Semua" button on the home
/// screen's recent-notifications section.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scroll = ScrollController();
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bootstrapped) return;
      _bootstrapped = true;
      final p = context.read<NotificationProvider>();
      if (p.state == NotificationLoadState.idle) {
        p.load();
      }
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<NotificationProvider>().loadMore();
    }
  }

  Future<void> _refresh() async {
    await context.read<NotificationProvider>().load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        automaticallyImplyLeading: !widget.embeddedInShell,
        actions: [
          if (provider.hasUnread)
            TextButton.icon(
              onPressed: () => provider.markAllRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Baca semua'),
            ),
        ],
      ),
      body: _buildBody(provider, theme),
    );
  }

  Widget _buildBody(NotificationProvider provider, ThemeData theme) {
    if (provider.state == NotificationLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.state == NotificationLoadState.error &&
        provider.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 14),
              Text(
                'Gagal memuat notifikasi',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => provider.load(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Notifikasi akan muncul saat status\npeminjaman Anda berubah.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount:
            provider.items.length +
            (provider.state == NotificationLoadState.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          if (index == provider.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notif = provider.items[index];
          return _NotificationTile(
            notification: notif,
            onTap: () => provider.markRead(notif.id),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification tile
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _meta(notification.type, theme);
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isUnread
            ? meta.accent.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: meta.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(meta.icon, color: meta.accent, size: 22),
            ),
            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isUnread
                                ? null
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: meta.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _relativeTime(notification.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
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

  static _NotifMeta _meta(String type, ThemeData theme) {
    return switch (type) {
      AppNotification.typeLoanCreated => _NotifMeta(
        icon: Icons.pending_actions_rounded,
        accent: AppColors.statusPending,
      ),
      AppNotification.typeLoanApproved => _NotifMeta(
        icon: Icons.check_circle_rounded,
        accent: AppColors.statusApproved,
      ),
      AppNotification.typeLoanRejected => _NotifMeta(
        icon: Icons.cancel_rounded,
        accent: AppColors.statusRejected,
      ),
      AppNotification.typeLoanBorrowed => _NotifMeta(
        icon: Icons.outbox_rounded,
        accent: AppColors.statusBorrowed,
      ),
      AppNotification.typeLoanReturned => _NotifMeta(
        icon: Icons.move_to_inbox_rounded,
        accent: AppColors.statusReturned,
      ),
      _ => _NotifMeta(
        icon: Icons.notifications_rounded,
        accent: AppColors.info,
      ),
    };
  }

  static String _relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} minggu yang lalu';
    }
    if (diff.inDays < 365) {
      return '${(diff.inDays / 30).floor()} bulan yang lalu';
    }
    return '${(diff.inDays / 365).floor()} tahun yang lalu';
  }
}

class _NotifMeta {
  const _NotifMeta({required this.icon, required this.accent});
  final IconData icon;
  final Color accent;
}
