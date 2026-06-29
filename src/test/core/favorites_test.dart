import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:acorde/services/database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.dbName = inMemoryDatabasePath;
  });

  setUp(() async {
    DatabaseService.reset();
  });

  test('DatabaseService favorite functionality', () async {
    final song = SavedSong(
      sourceId: '123',
      title: 'Alma de Diamante',
      artist: 'Spinetta',
      lyrics: 'Letra...',
      chords: 'A B C',
      source: 'lacuerda',
      url: 'http://acordes.lacuerda.net/spinetta/alma_de_diamante',
      createdAt: DateTime.now().toIso8601String(),
    );

    // Save song
    final id = await DatabaseService.saveSong(song);
    expect(id, isNotNull);

    // Get song and assert it's not a favorite initially
    var retrieved = await DatabaseService.getSongById(id);
    expect(retrieved, isNotNull);
    expect(retrieved!.isFavorite, isFalse);

    // Make it a favorite
    await DatabaseService.setFavorite(id, true);

    // Get song again
    retrieved = await DatabaseService.getSongById(id);
    expect(retrieved!.isFavorite, isTrue);

    // Retrieve favorite songs list
    final favorites = await DatabaseService.getSongs(onlyFavorites: true);
    expect(favorites.length, equals(1));
    expect(favorites.first.title, equals('Alma de Diamante'));

    // Search local favorite songs list
    final searchFav = await DatabaseService.searchLocalSongs(
      'Alma',
      onlyFavorites: true,
    );
    expect(searchFav.length, equals(1));

    final searchFavNoMatch = await DatabaseService.searchLocalSongs(
      'Soda',
      onlyFavorites: true,
    );
    expect(searchFavNoMatch.length, equals(0));

    // Remove from favorite
    await DatabaseService.setFavorite(id, false);
    retrieved = await DatabaseService.getSongById(id);
    expect(retrieved!.isFavorite, isFalse);

    final emptyFavorites = await DatabaseService.getSongs(onlyFavorites: true);
    expect(emptyFavorites.length, equals(0));
  });
}
