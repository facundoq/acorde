import * as SQLite from 'expo-sqlite';
import { Platform } from 'react-native';

export interface SavedSong {
  id: number;
  source_id: string;
  title: string;
  artist: string;
  lyrics: string;
  chords: string;
  source: string;
  url: string;
  created_at: string;
  instrument?: string;
  rating?: number;
}

const LOCAL_STORAGE_KEY = 'acorde_tabs';

let db: SQLite.SQLiteDatabase | null = null;

export const initDatabase = async () => {
  if (Platform.OS === 'web') {
    await seedLocalStorage();
    return null;
  }

  if (db) return db;
  db = await SQLite.openDatabaseAsync('acorde_tabs.db');
  
  await db.execAsync(`
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS songs (
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
    );
  `);

  await seedDatabase(db);
  
  return db;
};

const DEFAULT_SONG: Omit<SavedSong, 'id' | 'created_at'> = {
  source_id: '/the-beatles/yellow-submarine-chords-1047118',
  title: 'Yellow Submarine',
  artist: 'The Beatles',
  lyrics: 'In the town where I was born\nLived a man who sailed to sea\nAnd he told us of his life\nIn the land of submarines...',
  chords: 'G D C G\nEm Am C D\nG D C G\nEm Am C D\n\nG D\nWe all live in a yellow submarine\nD G\nYellow submarine, yellow submarine',
  source: 'ultimateguitar',
  url: 'https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-1047118',
  instrument: 'Chords',
  rating: 4.8
};

const seedLocalStorage = async () => {
  if (typeof window !== 'undefined') {
    const existing = window.localStorage.getItem(LOCAL_STORAGE_KEY);
    if (!existing || JSON.parse(existing).length === 0) {
      const songs = [{ ...DEFAULT_SONG, id: Date.now(), created_at: new Date().toISOString() }];
      window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(songs));
    }
  }
};

const seedDatabase = async (database: SQLite.SQLiteDatabase) => {
  const count = await database.getFirstAsync<{ 'COUNT(*)': number }>('SELECT COUNT(*) FROM songs');
  if (count && count['COUNT(*)'] === 0) {
    await database.runAsync(
      `INSERT INTO songs (source_id, title, artist, lyrics, chords, source, url, instrument, rating) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        DEFAULT_SONG.source_id,
        DEFAULT_SONG.title,
        DEFAULT_SONG.artist,
        DEFAULT_SONG.lyrics,
        DEFAULT_SONG.chords,
        DEFAULT_SONG.source,
        DEFAULT_SONG.url,
        DEFAULT_SONG.instrument || null,
        DEFAULT_SONG.rating || null
      ]
    );
  }
};

export const saveSong = async (song: Omit<SavedSong, 'id' | 'created_at'>) => {
  if (Platform.OS === 'web') {
    const existing = await getSongs();
    const newSong: SavedSong = {
      ...song,
      id: Date.now(),
      created_at: new Date().toISOString()
    };
    const filtered = existing.filter(s => !(s.source === song.source && s.source_id === song.source_id));
    const updated = [newSong, ...filtered];
    window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(updated));
    return newSong.id;
  }

  const database = await initDatabase();
  const result = await database!.runAsync(
    `INSERT OR REPLACE INTO songs (source_id, title, artist, lyrics, chords, source, url, instrument, rating) 
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [song.source_id, song.title, song.artist, song.lyrics, song.chords, song.source, song.url, song.instrument || null, song.rating || null]
  );
  return result.lastInsertRowId;
};

export const getSongs = async (): Promise<SavedSong[]> => {
  if (Platform.OS === 'web') {
    const data = window.localStorage.getItem(LOCAL_STORAGE_KEY);
    return data ? JSON.parse(data) : [];
  }

  const database = await initDatabase();
  return await database!.getAllAsync<SavedSong>('SELECT * FROM songs ORDER BY created_at DESC');
};

export const getSongById = async (id: number): Promise<SavedSong | null> => {
  if (Platform.OS === 'web') {
    const songs = await getSongs();
    return songs.find(s => s.id === id) || null;
  }

  const database = await initDatabase();
  return await database!.getFirstAsync<SavedSong>('SELECT * FROM songs WHERE id = ?', [id]);
};

export const searchLocalSongs = async (query: string): Promise<SavedSong[]> => {
  if (Platform.OS === 'web') {
    const songs = await getSongs();
    const q = query.toLowerCase();
    return songs.filter(s => s.title.toLowerCase().includes(q) || s.artist.toLowerCase().includes(q));
  }

  const database = await initDatabase();
  return await database!.getAllAsync<SavedSong>(
    'SELECT * FROM songs WHERE title LIKE ? OR artist LIKE ? ORDER BY created_at DESC',
    [`%${query}%`, `%${query}%`]
  );
};

export const deleteSong = async (id: number) => {
  if (Platform.OS === 'web') {
    const songs = await getSongs();
    const updated = songs.filter(s => s.id !== id);
    window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(updated));
    return;
  }

  const database = await initDatabase();
  await database!.runAsync('DELETE FROM songs WHERE id = ?', [id]);
};
