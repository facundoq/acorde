import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:acorde/main.dart';
import 'package:acorde/services/database.dart';
import 'package:acorde/ui/screens/home_tabs.dart';
import 'package:acorde/ui/screens/search_screen.dart';
import 'package:acorde/ui/screens/collection_screen.dart';
import 'package:acorde/ui/screens/diagrams_screen.dart';
import 'package:acorde/ui/screens/tuner_screen.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for sqlite testing in VM
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Use in-memory database path for tests
    DatabaseService.dbName = inMemoryDatabasePath;
  });

  setUp(() {
    DatabaseService.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App main navigation tabs smoke test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the HomeTabs screen is rendered
    expect(find.byType(HomeTabs), findsOneWidget);

    // Verify the tabs are rendered in the NavigationBar
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Diagrams'), findsOneWidget);
    expect(find.text('Tuner'), findsOneWidget);

    // Verify we start on the Collection Screen
    expect(find.byType(CollectionScreen), findsOneWidget);
    expect(find.text('Acorde'), findsWidgets);

    // Switch to Search tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);

    // Switch to Diagrams tab
    await tester.tap(find.text('Diagrams'));
    await tester.pumpAndSettle();

    // Verify Diagrams screen is visible
    expect(find.byType(DiagramsScreen), findsOneWidget);

    // Switch to Tuner tab
    await tester.tap(find.text('Tuner'));
    await tester.pumpAndSettle();

    // Verify Tuner screen is visible
    expect(find.byType(TunerScreen), findsOneWidget);

    // Switch back to Collection tab
    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();
    expect(find.byType(CollectionScreen), findsOneWidget);
  });
}
