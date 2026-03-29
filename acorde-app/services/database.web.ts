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

export const initDatabase = async () => {
  if (typeof window !== 'undefined') {
    const existing = window.localStorage.getItem(LOCAL_STORAGE_KEY);
    if (!existing || JSON.parse(existing).length === 0) {
      const songs = [{ ...DEFAULT_SONG, id: Date.now(), created_at: new Date().toISOString() }];
      window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(songs));
    }
  }
  return null;
};

export const saveSong = async (song: Omit<SavedSong, 'id' | 'created_at'>) => {
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
};

export const getSongs = async (): Promise<SavedSong[]> => {
  if (typeof window === 'undefined') return [];
  const data = window.localStorage.getItem(LOCAL_STORAGE_KEY);
  return data ? JSON.parse(data) : [];
};

export const getSongById = async (id: number): Promise<SavedSong | null> => {
  const songs = await getSongs();
  return songs.find(s => s.id === id) || null;
};

export const searchLocalSongs = async (query: string): Promise<SavedSong[]> => {
  const songs = await getSongs();
  const q = query.toLowerCase();
  return songs.filter(s => s.title.toLowerCase().includes(q) || s.artist.toLowerCase().includes(q));
};

export const deleteSong = async (id: number) => {
  const songs = await getSongs();
  const updated = songs.filter(s => s.id !== id);
  window.localStorage.setItem(LOCAL_STORAGE_KEY, JSON.stringify(updated));
};
