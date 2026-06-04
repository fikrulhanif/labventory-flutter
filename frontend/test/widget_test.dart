// Smoke test for the Labventory shell.
//
// We exercise just the splash branding so widget_test stays a fast
// boot-sanity check. Auth/inventory/loan tests with proper mocks are
// added under test/services and test/providers.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labventory/providers/auth_provider.dart';
import 'package:labventory/screens/splash/splash_screen.dart';
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
        child: MaterialApp(
          home: const SplashScreen(),
          // The splash screen calls `pushReplacementNamed('/login')` once
          // its async bootstrap completes. Without these stubs the test
          // explodes with `Could not find a generator for route` the
          // moment the navigation kicks in. The stubs render an empty
          // Scaffold so the test focuses on splash branding only.
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => const Scaffold(),
          ),
        ),
      ),
    );

    // First frame: splash branding is on screen, async bootstrap still
    // running. We assert before pumping further so the navigation has
    // not yet replaced the splash widget.
    await tester.pump();

    expect(find.text('Labventory'), findsOneWidget);
    expect(find.text('Campus laboratory inventory borrowing'), findsOneWidget);

    // Drain any pending timers/microtasks so the test exits cleanly
    // (the splash screen's post-bootstrap navigation finishes here).
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
