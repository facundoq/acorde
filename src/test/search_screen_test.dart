// test/search_screen_test.dart
//
// Widget tests for SearchScreen with an injected mock source.
// Verifies that when a search returns results, the UI displays them correctly —
// independent of any real network calls.
//
// The search button is an ElevatedButton labeled 'Add Online' that only appears
// when the query is longer than 2 characters.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:acorde/core/models.dart';
import 'package:acorde/core/sources/source.dart';
import 'package:acorde/services/database.dart';
import 'package:acorde/ui/screens/search_screen.dart';

// ---------------------------------------------------------------------------
// Mock Source
// ---------------------------------------------------------------------------

class MockUGSource implements Source {
  @override
  final String name = 'ultimateguitar';

  final List<SongSearchResult> searchResults;
  final SongContent? songContent;

  MockUGSource({required this.searchResults, this.songContent});

  @override
  Future<List<SongSearchResult>> search(String query) async {
    // Simulate a short network delay so we can test the loading state.
    await Future.delayed(const Duration(milliseconds: 50));
    return searchResults;
  }

  @override
  Future<SongContent> getSong(String url) async {
    if (songContent != null) return songContent!;
    throw UnimplementedError('getSong not needed for this test');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildTestApp(SearchScreen searchScreen) {
  return MaterialApp(home: searchScreen);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.dbName = inMemoryDatabasePath;
  });

  setUp(() {
    DatabaseService.reset();
    SharedPreferences.setMockInitialValues({
      // Enable ultimateguitar source
      'sources_config':
          '{"ultimateguitar":true,"cifraclub":false,"lacuerda":false,"cifras":false}',
    });
  });

  group('SearchScreen with mock UltimateGuitar source', () {
    testWidgets('renders the search field and app bar on startup', (
      WidgetTester tester,
    ) async {
      final screen = SearchScreen(sources: [MockUGSource(searchResults: [])]);
      await tester.pumpWidget(buildTestApp(screen));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Acorde'), findsOneWidget);
    });

    testWidgets('"Search" button appears only when query length > 2', (
      WidgetTester tester,
    ) async {
      final screen = SearchScreen(sources: [MockUGSource(searchResults: [])]);
      await tester.pumpWidget(buildTestApp(screen));
      await tester.pumpAndSettle();

      // Button should NOT appear for a short query
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pumpAndSettle();
      expect(find.text('Search'), findsNothing);

      // Button SHOULD appear for a query longer than 2 chars
      await tester.enterText(find.byType(TextField), 'yellow');
      await tester.pumpAndSettle();
      expect(
        find.text('Search'),
        findsWidgets,
      ); // TextField prefix icon might contain Search, or the button
    });

    testWidgets(
      'search results from mock source appear in the list after tapping Search',
      (WidgetTester tester) async {
        final mockResults = [
          SongSearchResult(
            id: 'https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-1',
            title: 'Yellow Submarine',
            artist: 'The Beatles',
            source: 'ultimateguitar',
            url:
                'https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-1',
            instrument: 'Chords',
            rating: 4.8,
          ),
          SongSearchResult(
            id: 'https://www.ultimate-guitar.com/tab/coldplay/yellow-chords-2',
            title: 'Yellow',
            artist: 'Coldplay',
            source: 'ultimateguitar',
            url: 'https://www.ultimate-guitar.com/tab/coldplay/yellow-chords-2',
            instrument: 'Chords',
            rating: 4.6,
          ),
        ];

        final screen = SearchScreen(
          sources: [MockUGSource(searchResults: mockResults)],
        );
        await tester.pumpWidget(buildTestApp(screen));
        await tester.pumpAndSettle();

        // Type a query longer than 2 chars to reveal the "Search" button
        await tester.enterText(find.byType(TextField), 'yellow');
        await tester.pumpAndSettle();

        // Tap "Search" button (the elevated button, not the search icon in TextField)
        final searchButton = find.widgetWithText(ElevatedButton, 'Search');
        expect(searchButton, findsOneWidget);
        await tester.tap(searchButton);

        // Allow the async search (50 ms mock delay + setState) to complete
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // The section header "Online Results" must be visible
        expect(find.text('Online Results'), findsOneWidget);

        // Both result titles must appear in the rendered widget tree
        expect(find.text('Yellow Submarine'), findsOneWidget);
        expect(find.text('Yellow'), findsWidgets); // also in text field
        expect(find.text('The Beatles'), findsOneWidget);
        expect(find.text('Coldplay'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "No online results" status when source returns empty list',
      (WidgetTester tester) async {
        final screen = SearchScreen(sources: [MockUGSource(searchResults: [])]);
        await tester.pumpWidget(buildTestApp(screen));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'xyznotexist999');
        await tester.pumpAndSettle();

        final searchButton = find.widgetWithText(ElevatedButton, 'Search');
        await tester.tap(searchButton);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Should show the no-results status message
        expect(find.textContaining('No online results'), findsOneWidget);
      },
    );
  });
}
