export interface SongSearchResult {
  id: string; // Internal id for the source
  title: string;
  artist: string;
  source: string; // e.g., 'cifraclub'
  url: string;
  instrument?: string; // e.g., 'Chords', 'Tab', 'Bass'
  rating?: number; // 0 to 5
}

export interface SongContent {
  title: string;
  artist: string;
  lyrics: string;
  chords?: string;
  url: string;
  source: string;
  instrument?: string;
  rating?: number;
}
