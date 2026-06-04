import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../inventory/list_screen.dart';
import '../loan/history_screen.dart';
import '../profile/profile_screen.dart';

/// Top-level shell with a Material 3 NavigationBar. Replaces the
/// previous "/home" placeholder so the app feels like a proper mobile
/// experience: Home, Inventory, My Loans, Profile.
///
/// Uses an [IndexedStack] so each tab keeps its scroll position and
/// any in-flight requests when the user switches and comes back.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialTab = 0});

  final int initialTab;

  /// Look up the closest [AppShellController] from any descendant.
  /// Used by Home to programmatically switch tabs (e.g. when a user
  /// taps a category card or a "see all" button).
  static AppShellController? of(BuildContext context) {
    return context.findAncestorStateOfType<_AppShellState>()?._controller;
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

/// Tiny controller exposed via [AppShell.of] so descendants can switch
/// tabs without reaching into private state.
class AppShellController extends ChangeNotifier {
  AppShellController(int initial) : _index = initial;

  int _index;
  int get index => _index;

  void setIndex(int next) {
    final clamped = next.clamp(0, 3);
    if (clamped == _index) return;
    _index = clamped;
    notifyListeners();
  }
}

class _AppShellState extends State<AppShell> {
  late final AppShellController _controller;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: 'Inventory',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment_rounded),
      label: 'Loans',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AppShellController(widget.initialTab)
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
          HomeScreen(),
          InventoryListScreen(embeddedInShell: true),
          LoanHistoryScreen(embeddedInShell: true),
          ProfileScreen(embeddedInShell: true),
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
