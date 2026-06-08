import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acorde/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App UI Test', () {
    testWidgets('verify navigation, search field, diagrams expansion, and tuner tab',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify we start on "My Tabs" search screen
      expect(find.text('Acorde'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Yellow Submarine');
      await tester.pumpAndSettle();

      // 2. Switch to the Diagrams tab
      await tester.tap(find.text('Diagrams'));
      await tester.pumpAndSettle();

      // Verify Chord Diagrams view
      expect(find.text('Chord Diagrams'), findsOneWidget);

      // Search for C chord
      await tester.enterText(find.byType(TextField), 'C');
      await tester.pumpAndSettle();

      // Tap on the chord tile to expand it inline
      await tester.tap(find.text('C').first);
      await tester.pumpAndSettle();

      // 3. Switch to the Tuner tab
      await tester.tap(find.text('Tuner'));
      await tester.pumpAndSettle();

      // Verify Tuner view
      expect(find.text('Guitar Tuner'), findsOneWidget);
      expect(find.text('Start Tuning'), findsOneWidget);
    });
  });
}
