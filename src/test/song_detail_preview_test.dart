import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:acorde/core/models.dart';
import 'package:acorde/core/sources/source.dart';
import 'package:acorde/services/database.dart';
import 'package:acorde/ui/screens/song_detail_screen.dart';

class MockUGSource implements Source {
  @override
  final String name = 'ultimateguitar';

  final SongContent songContent;

  MockUGSource({required this.songContent});

  @override
  Future<List<SongSearchResult>> search(String query) async {
    return [];
  }

  @override
  Future<SongContent> getSong(String url) async {
    return songContent;
  }
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
    await DatabaseService.database; // Pre-initialize database
  });

  Widget buildTestApp(Widget screen) {
    return MaterialApp(home: screen);
  }

  testWidgets('SongDetailScreen preview and toggle save/remove flow', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      final searchResult = SongSearchResult(
        id: 'mock-song-123',
        title: 'Imagine Preview',
        artist: 'John Lennon Preview',
        source: 'ultimateguitar',
        url: 'https://example.com/imagine-preview',
        instrument: 'Chords',
        rating: 4.5,
      );

      final mockSongContent = SongContent(
        title: 'Imagine Preview',
        artist: 'John Lennon Preview',
        lyrics: 'Imagine all the people living life in peace',
        chords: '[tab][ch]C[/ch]Imagine all the [ch]F[/ch]people[/tab]',
        url: 'https://example.com/imagine-preview',
        source: 'ultimateguitar',
        instrument: 'Chords',
        rating: 4.5,
      );

      final mockSource = MockUGSource(songContent: mockSongContent);
      final detailScreen = SongDetailScreen(
        searchResult: searchResult,
        sources: [mockSource],
      );

      await tester.pumpWidget(buildTestApp(detailScreen));

      // Wait for async loading to complete
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        final hasIndicator = find
            .byType(CircularProgressIndicator)
            .evaluate()
            .isNotEmpty;
        if (!hasIndicator) break;
      }

      // Verify song details and chords are displayed
      expect(
        find.text('Imagine Preview'),
        findsWidgets,
      ); // Title in app bar and header
      expect(find.text('John Lennon Preview'), findsOneWidget);
      expect(find.text('SOURCE: ULTIMATEGUITAR'), findsOneWidget);
      expect(find.text('C'), findsWidgets);
      expect(find.text('F'), findsWidgets);

      // 2. Verify "Save to collection" button is displayed
      final saveButtonFinder = find.text('Save to collection');
      expect(saveButtonFinder, findsOneWidget);

      // Verify it is not in the database yet
      var savedSongs = await DatabaseService.getSongs();
      expect(savedSongs.length, equals(0));
      expect(savedSongs.any((s) => s.title == 'Imagine Preview'), isFalse);

      // 3. Tap "Save to collection"
      await tester.tap(saveButtonFinder);

      // Wait for save operation
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find.text('Remove from collection').evaluate().isNotEmpty) break;
      }

      // Verify button text changed to "Remove from collection"
      expect(find.text('Remove from collection'), findsOneWidget);

      // Verify it is now saved in the database
      savedSongs = await DatabaseService.getSongs();
      expect(savedSongs.length, equals(1));
      expect(savedSongs.any((s) => s.title == 'Imagine Preview'), isTrue);

      // 4. Tap "Remove from collection"
      await tester.tap(find.text('Remove from collection'));

      // Wait for remove operation
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find.text('Save to collection').evaluate().isNotEmpty) break;
      }

      // Verify button text changed back to "Save to collection"
      expect(find.text('Save to collection'), findsOneWidget);

      // Verify it is deleted from the database
      savedSongs = await DatabaseService.getSongs();
      expect(savedSongs.length, equals(0));
      expect(savedSongs.any((s) => s.title == 'Imagine Preview'), isFalse);
    });
  });

  testWidgets('SongDetailScreen auto-scroll controls and long press to stop', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      final searchResult = SongSearchResult(
        id: 'mock-song-123',
        title: 'Imagine Preview',
        artist: 'John Lennon Preview',
        source: 'ultimateguitar',
        url: 'https://example.com/imagine-preview',
        instrument: 'Chords',
        rating: 4.5,
      );

      final mockSongContent = SongContent(
        title: 'Imagine Preview',
        artist: 'John Lennon Preview',
        lyrics: 'Imagine all the people living life in peace',
        chords: '[tab][ch]C[/ch]Imagine all the [ch]F[/ch]people[/tab]',
        url: 'https://example.com/imagine-preview',
        source: 'ultimateguitar',
        instrument: 'Chords',
        rating: 4.5,
      );

      final mockSource = MockUGSource(songContent: mockSongContent);
      final detailScreen = SongDetailScreen(
        searchResult: searchResult,
        sources: [mockSource],
      );

      await tester.pumpWidget(buildTestApp(detailScreen));

      // Wait for async loading to complete
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        final hasIndicator = find
            .byType(CircularProgressIndicator)
            .evaluate()
            .isNotEmpty;
        if (!hasIndicator) break;
      }

      // Initially we should find the play arrow icon
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      final autoScrollButton = find.byType(OutlinedButton);

      // Tap once to start at 1x
      await tester.tap(autoScrollButton);
      await tester.pumpAndSettle();
      expect(find.text('1x'), findsOneWidget);

      // Tap again to switch to 2x
      await tester.tap(autoScrollButton);
      await tester.pumpAndSettle();
      expect(find.text('2x'), findsOneWidget);

      // Long press to stop auto scroll (invoke callback directly to avoid test timer/clock issues)
      final OutlinedButton buttonWidget = tester.widget<OutlinedButton>(
        autoScrollButton,
      );
      buttonWidget.onLongPress?.call();
      await tester.pumpAndSettle();

      // Should be stopped (back to play_arrow icon)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('2x'), findsNothing);
    });
  });
}
