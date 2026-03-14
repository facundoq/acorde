import { SongSearchResult, SongContent } from '../types';

export interface Source {
  name: string;
  search(query: string): Promise<SongSearchResult[]>;
  getSong(url: string): Promise<SongContent>;
}