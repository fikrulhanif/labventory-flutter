// Smoke test for the Labventory bootstrap screen.
//
// This is a temporary test that just verifies the app boots and renders the
// branded landing screen. Real screen/provider/widget tests are added in the
// Flutter implementation tasks.

import 'package:flutter_test/flutter_test.dart';

import 'package:labventory/main.dart';

void main() {
  testWidgets('Labventory bootstrap screen renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LabventoryApp());

    expect(find.text('Labventory'), findsOneWidget);
    expect(find.text('Campus laboratory inventory borrowing'), findsOneWidget);
  });
}
