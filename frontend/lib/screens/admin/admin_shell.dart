import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_qr_screen.dart';

/// Top-level shell for staff (admin/laboran) users, mirroring the student
/// [AppShell] controller pattern. Tabs: Dashboard, QR Scanner, Profil.
///
/// "Peminjaman Aktif" is reached contextually from the QR/lookup flow
/// (a scan resolves to the active loans for that inventory), so it is not
/// a standalone tab — the scanner tab is the entry point for operations.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.initialTab = 0});

  final int initialTab;

  static AdminShellController? of(BuildContext context) {
    return context.findAncestorStateOfType<_AdminShellState>()?._controller;
  }

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class AdminShellController extends ChangeNotifier {
  AdminShellController(int initial) : _index = initial;

  int _index;
  int get index => _index;

  void setIndex(int next) {
    final clamped = next.clamp(0, 2);
    if (clamped == _index) return;
    _index = clamped;
    notifyListeners();
  }
}

class _AdminShellState extends State<AdminShell> {
  late final AdminShellController _controller;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: 'Dasbor',
    ),
    NavigationDestination(
      icon: Icon(Icons.qr_code_scanner_outlined),
      selectedIcon: Icon(Icons.qr_code_scanner_rounded),
      label: 'Pindai QR',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AdminShellController(widget.initialTab)
      ..addListener(_onControllerChanged);
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
    return Scaffold(
      body: IndexedStack(
        index: _controller.index,
        children: const [
          AdminDashboardScreen(),
          AdminQrScreen(),
          AdminProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _controller.index,
        onDestinationSelected: _controller.setIndex,
        destinations: _destinations,
      ),
    );
  }
}
