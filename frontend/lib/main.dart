import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'routes/app_router.dart';
import 'services/dio_client.dart';

void main() {
  // Build the Dio singleton early so AuthInterceptor + ResponseInterceptor
  // are wired before any service request fires.
  DioClient.instance;

  runApp(const LabventoryApp());
}

class LabventoryApp extends StatelessWidget {
  const LabventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Hand the on-401 callback to the Dio client so the response
          // interceptor can cleanly bounce back to /login when a token
          // is revoked from outside the splash bootstrap.
          DioClient.configureOnUnauthenticated(() {
            context.read<AuthProvider>().onTokenRevoked();
          });

          return MaterialApp(
            title: 'Labventory',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: ThemeMode.system,
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
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
