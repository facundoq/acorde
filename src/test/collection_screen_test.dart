import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:acorde/services/database.dart';
import 'package:acorde/ui/screens/collection_screen.dart';

Widget buildTestApp(Widget screen) {
  return MaterialApp(home: screen);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.dbName = inMemoryDatabasePath;
  });

  setUp(() async {
    DatabaseService.reset();
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseService.database; // Pre-initialize database
    await db.delete(
      'songs',
    ); // Clear any seeded or leftover songs for total test isolation
  });

  group('CollectionScreen tests', () {
    testWidgets('renders empty state when there are no saved songs', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestApp(const CollectionScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Your Collection list is empty'), findsOneWidget);
        expect(find.text('Discover Songs'), findsOneWidget);
      });
    });

    testWidgets('renders list of saved songs', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final song = SavedSong(
          sourceId: '123',
          title: 'Yesterday',
          artist: 'The Beatles',
          lyrics: 'lyrics',
          chords: 'chords',
          source: 'ultimateguitar',
          url: 'https://example.com/yesterday',
          createdAt: '2026-06-09',
          instrument: 'Chords',
          rating: 4.8,
        );
        await DatabaseService.saveSong(song);

        await tester.pumpWidget(buildTestApp(const CollectionScreen()));
        // Wait for async load from SQLite database
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Yesterday'), findsOneWidget);
        expect(find.text('The Beatles'), findsOneWidget);
        expect(find.text('1 Tabs'), findsOneWidget);
      });
    });

    testWidgets(
      'filters saved songs and shows search online button when not found',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final song = SavedSong(
            sourceId: '123',
            title: 'Yesterday',
            artist: 'The Beatles',
            lyrics: 'lyrics',
            chords: 'chords',
            source: 'ultimateguitar',
            url: 'https://example.com/yesterday',
            createdAt: '2026-06-09',
            instrument: 'Chords',
            rating: 4.8,
          );
          await DatabaseService.saveSong(song);

          String? triggeredQuery;
          await tester.pumpWidget(
            buildTestApp(
              CollectionScreen(
                onSearchOnline: (q) {
                  triggeredQuery = q;
                },
              ),
            ),
          );
          // Wait for async load from SQLite database
          await Future.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          // Type a query that matches nothing
          await tester.enterText(find.byType(TextField), 'imagine');
          // Wait for filtering query async query to run
          await Future.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          expect(find.text('Yesterday'), findsNothing);
          expect(find.text('No matching local songs'), findsOneWidget);

          final onlineSearchBtn = find.widgetWithText(
            ElevatedButton,
            'Search online for "imagine"',
          );
          expect(onlineSearchBtn, findsOneWidget);

          await tester.tap(onlineSearchBtn);
          await tester.pumpAndSettle();

          expect(triggeredQuery, equals('imagine'));
        });
      },
    );
  });
}
