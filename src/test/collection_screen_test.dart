import 'package:flutter/gestures.dart';
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
    testWidgets('renders loading state initially', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestApp(const CollectionScreen()));
        await tester.pump(); // Render first frame containing loading animation

        expect(find.text('Loading collection...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    testWidgets('renders empty state when there are no saved songs', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(buildTestApp(const CollectionScreen()));
        // Wait for async load from SQLite database to complete
        await Future.delayed(const Duration(milliseconds: 100));
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

    testWidgets(
      'sorts songs by author then song title, and renders alphabet scrollbar',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          // Seed songs out of alphabetical order
          final song1 = SavedSong(
            sourceId: '1',
            title: 'Yesterday',
            artist: 'The Beatles',
            lyrics: 'lyrics',
            chords: 'chords',
            source: 'ultimateguitar',
            url: 'https://example.com/1',
            createdAt: '2026-06-09',
          );
          final song2 = SavedSong(
            sourceId: '2',
            title: 'A Hard Day\'s Night',
            artist: 'The Beatles',
            lyrics: 'lyrics',
            chords: 'chords',
            source: 'ultimateguitar',
            url: 'https://example.com/2',
            createdAt: '2026-06-09',
          );
          final song3 = SavedSong(
            sourceId: '3',
            title: 'Imagine',
            artist: 'John Lennon',
            lyrics: 'lyrics',
            chords: 'chords',
            source: 'ultimateguitar',
            url: 'https://example.com/3',
            createdAt: '2026-06-09',
          );

          await DatabaseService.saveSong(song1);
          await DatabaseService.saveSong(song2);
          await DatabaseService.saveSong(song3);

          await tester.pumpWidget(buildTestApp(const CollectionScreen()));
          await Future.delayed(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();

          // Verify alphabet scrollbar is visible with letters J and T
          expect(find.text('J'), findsOneWidget);
          expect(find.text('T'), findsOneWidget);

          // Verify sorted order in UI:
          // 1. John Lennon - Imagine (starts with J)
          // 2. The Beatles - A Hard Day's Night (starts with T, A before Y)
          // 3. The Beatles - Yesterday (starts with T, Y after A)
          final songTiles = find.byType(ListTile);
          expect(songTiles, findsNWidgets(3));

          final firstTile = tester.widget<ListTile>(songTiles.at(0));
          final secondTile = tester.widget<ListTile>(songTiles.at(1));
          final thirdTile = tester.widget<ListTile>(songTiles.at(2));

          expect((firstTile.title as Text).data, equals('Imagine'));
          expect(
            (secondTile.title as Text).data,
            equals('A Hard Day\'s Night'),
          );
          expect((thirdTile.title as Text).data, equals('Yesterday'));
        });
      },
    );

    testWidgets('triggers delete dialog on long press', (
      WidgetTester tester,
    ) async {
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
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Simulate manual long press
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(ListTile).first),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        await tester.pump();
        await gesture.up();

        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }

        expect(find.text('Delete Song'), findsOneWidget);
        expect(
          find.text(
            'Are you sure you want to delete "Yesterday" from your Collection?',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Cancel'));
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }

        expect(find.text('Delete Song'), findsNothing);
      });
    });

    testWidgets('triggers delete dialog on secondary tap (right click)', (
      WidgetTester tester,
    ) async {
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
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(ListTile).first),
          pointer: 7, // Custom pointer to avoid conflict
          buttons: kSecondaryMouseButton,
        );
        await gesture.up();
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }

        expect(find.text('Delete Song'), findsOneWidget);

        await tester.tap(find.text('Delete'));
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }

        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        expect(find.text('Yesterday'), findsNothing);
      });
    });
  });
}
