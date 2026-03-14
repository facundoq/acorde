export interface SongSearchResult {
  id: string; // Internal id for the source
  title: string;
  artist: string;
  source: string; // e.g., 'cifraclub'
  url: string;
}

export interface SongContent {
  title: string;
  artist: string;
  lyrics: string;
  chords?: string;
  url: string;
  source: string;
}