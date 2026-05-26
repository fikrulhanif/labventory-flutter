import 'package:flutter/material.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'services/dio_client.dart';

void main() {
  // Eagerly build the Dio singleton so the AuthInterceptor + ResponseInterceptor
  // are registered before any service fires its first request. Auth providers
  // and routers in later tasks (15+) will hook themselves to the on-401
  // callback via DioClient.configureOnUnauthenticated.
  DioClient.instance;

  runApp(const LabventoryApp());
}

class LabventoryApp extends StatelessWidget {
  const LabventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Labventory',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _BootstrapScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? AppColors.background
          : null,
    );

    return base.copyWith(
      textTheme: AppTextStyles.textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Temporary landing screen shown before the real splash, auth, and inventory
/// screens are wired up in Task 15+.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo_transparant.png', height: 120),
                const SizedBox(height: 24),
                Text(
                  'Labventory',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Campus laboratory inventory borrowing',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
