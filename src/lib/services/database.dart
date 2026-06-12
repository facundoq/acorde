import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class SavedSong {
  final int? id;
  final String sourceId;
  final String title;
  final String artist;
  final String lyrics;
  final String chords;
  final String source;
  final String url;
  final String createdAt;
  final String? instrument;
  final double? rating;

  SavedSong({
    this.id,
    required this.sourceId,
    required this.title,
    required this.artist,
    required this.lyrics,
    required this.chords,
    required this.source,
    required this.url,
    required this.createdAt,
    this.instrument,
    this.rating,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'source_id': sourceId,
      'title': title,
      'artist': artist,
      'lyrics': lyrics,
      'chords': chords,
      'source': source,
      'url': url,
      'instrument': instrument,
      'rating': rating,
    };
  }

  factory SavedSong.fromMap(Map<String, dynamic> map) {
    return SavedSong(
      id: map['id'] as int?,
      sourceId: map['source_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      lyrics: map['lyrics'] as String? ?? '',
      chords: map['chords'] as String? ?? '',
      source: map['source'] as String? ?? '',
      url: map['url'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      instrument: map['instrument'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }
}

class DatabaseService {
  static Database? _db;
  static String dbName = 'acorde_tabs.db';

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static void reset() {
    _db = null;
  }

  static Future<Database> _initDatabase() async {
    String path;
    if (dbName == inMemoryDatabasePath) {
      path = inMemoryDatabasePath;
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, dbName);
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_id TEXT,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            lyrics TEXT,
            chords TEXT,
            source TEXT,
            url TEXT,
            instrument TEXT,
            rating REAL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(source, source_id)
          )
        ''');
      },
    );
  }

  static Future<int> saveSong(SavedSong song) async {
    final db = await database;
    return await db.insert(
      'songs',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<SavedSong>> getSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SavedSong.fromMap(map)).toList();
  }

  static Future<SavedSong?> getSongById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SavedSong.fromMap(maps.first);
    }
    return null;
  }

  static Future<SavedSong?> getSongBySourceAndId(
    String source,
    String sourceId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'source = ? AND source_id = ?',
      whereArgs: [source, sourceId],
    );
    if (maps.isNotEmpty) {
      return SavedSong.fromMap(maps.first);
    }
    return null;
  }

  static Future<List<SavedSong>> searchLocalSongs(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'title LIKE ? OR artist LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SavedSong.fromMap(map)).toList();
  }

  static Future<void> deleteSong(int id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }
}
