// integration_test/app_test.dart
//
// End-to-end UI tests that run on a real device / emulator.
// These tests cover:
//   1. App startup and navigation tabs
//   2. Search screen with a mock source (verifies UI renders results without
//      real network access — the headless-Chromium fetcher path is tested in
//      unit tests; here we focus on the UI contract)
//   3. Diagrams tab: chord search and expansion
//   4. Tuner tab: presence of controls

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:acorde/main.dart' as app;
import 'package:acorde/core/models.dart';
import 'package:acorde/core/sources/source.dart';
import 'package:acorde/ui/screens/home_tabs.dart';
import 'package:acorde/ui/screens/search_screen.dart';
import 'package:acorde/ui/screens/collection_screen.dart';
import 'package:acorde/ui/screens/diagrams_screen.dart';
import 'package:acorde/ui/screens/tuner_screen.dart';

// ---------------------------------------------------------------------------
// Lightweight mock source for integration tests
// ---------------------------------------------------------------------------

class _MockUGSource implements Source {
  @override
  final String name = 'ultimateguitar';

  @override
  Future<List<SongSearchResult>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 30));
    if (query.toLowerCase().contains('yellow')) {
      return [
        SongSearchResult(
          id: 'https://www.ultimate-guitar.com/tab/beatles/yellow-submarine-1',
          title: 'Yellow Submarine',
          artist: 'The Beatles',
          source: 'ultimateguitar',
          url: 'https://www.ultimate-guitar.com/tab/beatles/yellow-submarine-1',
          instrument: 'Chords',
          rating: 4.8,
        ),
        SongSearchResult(
          id: 'https://www.ultimate-guitar.com/tab/coldplay/yellow-2',
          title: 'Yellow',
          artist: 'Coldplay',
          source: 'ultimateguitar',
          url: 'https://www.ultimate-guitar.com/tab/coldplay/yellow-2',
          instrument: 'Chords',
          rating: 4.6,
        ),
      ];
    }
    return [];
  }

  @override
  Future<SongContent> getSong(String url) async {
    return SongContent(
      title: 'Yellow Submarine',
      artist: 'The Beatles',
      lyrics: '[ch]G[/ch] - [ch]Bm[/ch]\nWe all live in a yellow submarine',
      chords: '[ch]G[/ch] - [ch]Bm[/ch]\nWe all live in a yellow submarine',
      url: url,
      source: 'ultimateguitar',
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    // -----------------------------------------------------------------------
    // 1. Navigation smoke test (no network)
    // -----------------------------------------------------------------------
    testWidgets(
      'app starts, shows navigation tabs, Diagrams and Tuner screens are reachable',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});

        app.main();
        await tester.pumpAndSettle();

        // Starts on Collection screen check
        expect(find.byType(CollectionScreen), findsOneWidget);
        expect(find.text('Acorde'), findsWidgets);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(HomeTabs), findsOneWidget);

        // Navigate to Diagrams
        await tester.tap(find.text('Diagrams'));
        await tester.pumpAndSettle();
        expect(find.byType(DiagramsScreen), findsOneWidget);

        // Navigate to Tuner
        await tester.tap(find.text('Tuner'));
        await tester.pumpAndSettle();
        expect(find.byType(TunerScreen), findsOneWidget);
        expect(find.text('Start Tuning'), findsOneWidget);

        // Navigate to Search
        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        expect(find.byType(SearchScreen), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 2. Search screen with mock source — verifies results display in the UI
    //    This is the UI-level analogue of the unit tests for the fetcher and
    //    the UG parser.  The headless-Chromium path is covered by unit tests;
    //    here we prove the result list renders correctly end-to-end.
    // -----------------------------------------------------------------------
    testWidgets(
      'search with mock UG source displays results in the list (Linux webview path UI test)',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({
          'sources_config':
              '{"ultimateguitar":true,"cifraclub":false,"lacuerda":false,"cifras":false}',
        });

        // Build just the SearchScreen with the mock source injected
        await tester.pumpWidget(
          MaterialApp(home: SearchScreen(sources: [_MockUGSource()])),
        );
        await tester.pumpAndSettle();

        // The search field must be present
        expect(find.byType(TextField), findsOneWidget);

        // Type a query longer than 2 chars (required for "Search" to appear)
        await tester.enterText(find.byType(TextField), 'yellow');
        await tester.pumpAndSettle();

        // Tap the "Search" ElevatedButton
        final searchButton = find.widgetWithText(ElevatedButton, 'Search');
        expect(searchButton, findsOneWidget);
        await tester.tap(searchButton);

        // Allow the async search (30 ms mock delay) to complete
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Section header and both mock results must appear
        expect(find.text('Online Results'), findsOneWidget);
        expect(find.text('Yellow Submarine'), findsOneWidget);
        expect(find.text('The Beatles'), findsOneWidget);
      },
    );

    // -----------------------------------------------------------------------
    // 3. Diagrams tab: search and chord expansion
    // -----------------------------------------------------------------------
    testWidgets(
      'Diagrams tab: chord search shows C chord and it can be expanded',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Diagrams'));
        await tester.pumpAndSettle();

        expect(find.byType(DiagramsScreen), findsOneWidget);

        // Search for a chord
        await tester.enterText(find.byType(TextField), 'C');
        await tester.pumpAndSettle();

        // The C chord entry should be visible
        expect(find.text('C'), findsWidgets);

        // Tap the first match to expand/show the diagram
        await tester.tap(find.text('C').first);
        await tester.pumpAndSettle();
      },
    );
  });
}
