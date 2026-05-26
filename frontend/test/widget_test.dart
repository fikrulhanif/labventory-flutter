// Smoke test for the Labventory shell.
//
// We exercise just the splash branding so widget_test stays a fast
// boot-sanity check. Auth/inventory/loan tests with proper mocks are
// added under test/services and test/providers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labventory/screens/splash/splash_screen.dart';
import 'package:labventory/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Splash screen renders Labventory branding', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    // Pump once to let the initial frame paint; we deliberately do NOT
    // pump-and-settle because the splash auto-navigates after bootstrap.
    await tester.pump();

    expect(find.text('Labventory'), findsOneWidget);
    expect(find.text('Campus laboratory inventory borrowing'), findsOneWidget);
  });
}
