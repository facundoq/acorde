import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:acorde/services/database.dart';

void main() {
  // Initialize FFI for local SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService Tests', () {
    setUp(() async {
      // Reset database singleton for each test
      DatabaseService.reset();
      DatabaseService.dbName = inMemoryDatabasePath;
      final db = await DatabaseService.database;
      await db.delete('songs');
    });

    test('should initialize database empty', () async {
      final db = await DatabaseService.database;
      expect(db, isNotNull);

      final songs = await DatabaseService.getSongs();
      expect(songs.length, equals(0));
    });

    test('should save and retrieve a song', () async {
      final newSong = SavedSong(
        sourceId: 'test-song-id',
        title: 'Imagine',
        artist: 'John Lennon',
        lyrics: 'Imagine all the people...',
        chords: 'C Cmaj7 F G',
        source: 'testsource',
        url: 'https://example.com/imagine',
        createdAt: '',
        instrument: 'Chords',
        rating: 5.0,
      );

      final insertId = await DatabaseService.saveSong(newSong);
      expect(insertId, greaterThan(0));

      final song = await DatabaseService.getSongById(insertId);
      expect(song, isNotNull);
      expect(song!.title, equals('Imagine'));
      expect(song.artist, equals('John Lennon'));
      expect(song.rating, equals(5.0));

      final allSongs = await DatabaseService.getSongs();
      expect(allSongs.length, equals(1)); // New only
    });

    test('should search local songs by title or artist', () async {
      final newSong = SavedSong(
        sourceId: 'test-song-id',
        title: 'Imagine',
        artist: 'John Lennon',
        lyrics: 'Imagine all the people...',
        chords: 'C Cmaj7 F G',
        source: 'testsource',
        url: 'https://example.com/imagine',
        createdAt: '',
        instrument: 'Chords',
        rating: 5.0,
      );
      await DatabaseService.saveSong(newSong);

      final beatlesSong = SavedSong(
        sourceId: 'test-song-id-2',
        title: 'Yellow Submarine',
        artist: 'The Beatles',
        lyrics: 'We all live in...',
        chords: 'G D C G',
        source: 'testsource',
        url: 'https://example.com/yellow',
        createdAt: '',
        instrument: 'Chords',
        rating: 4.8,
      );
      await DatabaseService.saveSong(beatlesSong);

      // Search by title
      var results = await DatabaseService.searchLocalSongs('Imag');
      expect(results.length, equals(1));
      expect(results[0].title, equals('Imagine'));

      // Search by artist
      results = await DatabaseService.searchLocalSongs('Lennon');
      expect(results.length, equals(1));
      expect(results[0].artist, equals('John Lennon'));

      // Search case insensitivity / partial
      results = await DatabaseService.searchLocalSongs('beatles');
      expect(results.length, equals(1));
      expect(results[0].artist, equals('The Beatles'));
    });

    test('should delete a song', () async {
      final newSong = SavedSong(
        sourceId: 'test-song-id',
        title: 'Imagine',
        artist: 'John Lennon',
        lyrics: 'Imagine all the people...',
        chords: 'C Cmaj7 F G',
        source: 'testsource',
        url: 'https://example.com/imagine',
        createdAt: '',
        instrument: 'Chords',
        rating: 5.0,
      );
      final id = await DatabaseService.saveSong(newSong);

      var allSongs = await DatabaseService.getSongs();
      expect(allSongs.length, equals(1));

      await DatabaseService.deleteSong(id);

      allSongs = await DatabaseService.getSongs();
      expect(allSongs.length, equals(0));
    });

    test('should get a song by source and sourceId', () async {
      final newSong = SavedSong(
        sourceId: 'test-source-id-123',
        title: 'Yesterday',
        artist: 'The Beatles',
        lyrics: 'Yesterday, all my troubles seemed so far away...',
        chords: 'F Em A7 Dm',
        source: 'testsource',
        url: 'https://example.com/yesterday',
        createdAt: '',
        instrument: 'Chords',
        rating: 4.9,
      );
      await DatabaseService.saveSong(newSong);

      final found = await DatabaseService.getSongBySourceAndId(
        'testsource',
        'test-source-id-123',
      );
      expect(found, isNotNull);
      expect(found!.title, equals('Yesterday'));

      final notFound = await DatabaseService.getSongBySourceAndId(
        'wrongsource',
        'test-source-id-123',
      );
      expect(notFound, isNull);
    });
  });
}
