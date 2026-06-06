import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../home/home_screen.dart';
import '../inventory/list_screen.dart';
import '../loan/history_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';

/// Top-level shell with a Material 3 NavigationBar.
/// Tabs: Beranda, Inventaris, Peminjaman, Notifikasi, Profil.
///
/// The Notifikasi tab shows an unread badge from [NotificationProvider].
/// Uses an [IndexedStack] so each tab retains state.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  final int initialTab;

  static AppShellController? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppShellState>()?._controller;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class AppShellController extends ChangeNotifier {
  AppShellController(int initial) : _index = initial;

  int _index;
  int get index => _index;

  void setIndex(int next) {
    final clamped = next.clamp(0, 4);
    if (clamped == _index) return;
    _index = clamped;
    notifyListeners();
  }
}

class _AppShellState extends State<AppShell> {
  late final AppShellController _controller;
  bool _notifBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AppShellController(widget.initialTab)
      ..addListener(_onControllerChanged);

    // Prime the unread count so the badge shows immediately after login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_notifBootstrapped) return;
      _notifBootstrapped = true;
      context.read<NotificationProvider>().refreshUnreadCount();
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _controller.index,
        children: const [
          HomeScreen(),
          InventoryListScreen(embeddedInShell: true),
          LoanHistoryScreen(embeddedInShell: true),
          NotificationScreen(embeddedInShell: true),
          ProfileScreen(embeddedInShell: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _controller.index,
        onDestinationSelected: (i) {
          _controller.setIndex(i);
          // When the user taps the Notifikasi tab, refresh the list so
          // the badge reflects the latest server state.
          if (i == 3) {
            context.read<NotificationProvider>().load(refresh: true);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Inventaris',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Peminjaman',
          ),
          // ── Notifikasi with badge ──────────────────────────────
          NavigationDestination(
            icon: _BadgedBell(unread: unread, selected: false),
            selectedIcon: _BadgedBell(unread: unread, selected: true),
            label: 'Notifikasi',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Bell icon with an optional unread count badge.
/// Shows a red dot for 1–9 and "9+" for 10+.
class _BadgedBell extends StatelessWidget {
  const _BadgedBell({required this.unread, required this.selected});

  final int unread;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? Icons.notifications_rounded : Icons.notifications_outlined,
    );

    if (unread == 0) return icon;

    return Badge(
      label: Text(unread > 9 ? '9+' : unread.toString()),
      child: icon,
    );
  }
}
