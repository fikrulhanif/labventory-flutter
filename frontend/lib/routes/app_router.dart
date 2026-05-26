import 'package:flutter/material.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/inventory/detail_screen.dart';
import '../screens/inventory/list_screen.dart';
import '../screens/loan/create_screen.dart';
import '../screens/loan/detail_screen.dart';
import '../screens/loan/history_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Centralized route table for the Labventory mobile app.
///
/// Routes that don't exist yet (inventory list/detail, loan create/history,
/// profile) are stubbed by Task 16/17 and will be wired here when the
/// corresponding screens land.
class AppRouter {
  AppRouter._();

  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String inventoryList = '/inventory';
  static const String inventoryDetail = '/inventory/detail';
  static const String loanCreate = '/loans/create';
  static const String loanHistory = '/loans/history';
  static const String loanDetail = '/loans/detail';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _build(settings, const SplashScreen());
      case login:
        return _build(settings, const LoginScreen());
      case register:
        return _build(settings, const RegisterScreen());
      case home:
        return _build(settings, const HomeScreen());
      case inventoryList:
        return _build(settings, const InventoryListScreen());
      case inventoryDetail:
        return _build(settings, const InventoryDetailScreen());
      case loanCreate:
        return _build(settings, const LoanCreateScreen());
      case loanHistory:
        return _build(settings, const LoanHistoryScreen());
      case loanDetail:
        return _build(settings, const LoanDetailScreen());
      case profile:
        return _build(settings, const ProfileScreen());
      case profileEdit:
        return _build(settings, const EditProfileScreen());
      default:
        return _build(
          settings,
          Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: Center(child: Text('No route for ${settings.name}')),
          ),
        );
    }
  }

  static MaterialPageRoute<dynamic> _build(
    RouteSettings settings,
    Widget child,
  ) {
    return MaterialPageRoute(settings: settings, builder: (_) => child);
  }
}
