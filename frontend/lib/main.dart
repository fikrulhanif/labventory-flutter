import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'services/dio_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Hand the on-401 callback to the Dio client so the response
          // interceptor can cleanly bounce back to /login when a token
          // is revoked from outside the splash bootstrap.
          DioClient.configureOnUnauthenticated(() {
            context.read<AuthProvider>().onTokenRevoked();
          });

          final themeMode = context.watch<ThemeProvider>().mode;

          return MaterialApp(
            title: 'Labventory',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeMode,
            initialRoute: AppRouter.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) {
              // Lock system UI overlay style to match the active theme so
              // status bar icons stay readable on both light and dark.
              final brightness = Theme.of(context).brightness;
              SystemChrome.setSystemUIOverlayStyle(
                brightness == Brightness.light
                    ? SystemUiOverlayStyle.dark.copyWith(
                        statusBarColor: Colors.transparent,
                        systemNavigationBarColor: AppColors.background,
                        systemNavigationBarIconBrightness: Brightness.dark,
                      )
                    : SystemUiOverlayStyle.light.copyWith(
                        statusBarColor: Colors.transparent,
                        systemNavigationBarColor: AppColors.backgroundDark,
                        systemNavigationBarIconBrightness: Brightness.light,
                      ),
              );
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
          surfaceContainerHigh: isLight
              ? const Color(0xFFEEF0F6)
              : AppColors.surfaceDarkElev,
          surfaceContainerHighest: isLight
              ? const Color(0xFFE8EBF2)
              : const Color(0xFF20242F),
          onSurface: isLight
              ? AppColors.textPrimary
              : AppColors.textPrimaryDark,
          onSurfaceVariant: isLight
              ? AppColors.textMuted
              : AppColors.textMutedDark,
          outline: isLight ? AppColors.borderLight : AppColors.borderDark,
          outlineVariant: isLight
              ? const Color(0xFFEFF1F5)
              : const Color(0xFF2A2F3B),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight
          ? AppColors.background
          : AppColors.backgroundDark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return base.copyWith(
      textTheme: AppTextStyles.textTheme(base.textTheme, brightness),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight
            ? AppColors.background
            : AppColors.backgroundDark,
        foregroundColor: isLight
            ? AppColors.textPrimary
            : AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.appBarTitle(brightness),
        iconTheme: IconThemeData(
          color: isLight ? AppColors.textPrimary : AppColors.textPrimaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDarkElev,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
            width: 0.6,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: isLight ? AppColors.borderLight : AppColors.borderDark,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDarkElev,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: isLight
            ? AppColors.surfaceLight
            : AppColors.surfaceDarkElev,
        selectedColor: scheme.primary.withValues(alpha: 0.12),
        side: BorderSide(color: scheme.outline, width: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: scheme.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 0.6,
        space: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceLight
            : AppColors.surfaceDark,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight
            ? AppColors.surfaceLight
            : AppColors.surfaceDark,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        elevation: 0,
        height: 68,
      ),
    );
  }
}
