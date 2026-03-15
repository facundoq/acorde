import { LaCuerdaSource } from '../sources/LaCuerdaSource';
import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';
import { CifrasSource } from '../sources/CifrasSource';

global.fetch = jest.fn();

describe('Additional Sources', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('LaCuerdaSource', () => {
    const source = new LaCuerdaSource();
    
    it('should parse search results correctly', async () => {
      const mockHtml = '<html><body><a href="/tabs/l/legiao_urbana/tempo_perdido.shtml">Tempo Perdido</a></body></html>';
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        text: () => Promise.resolve(mockHtml),
      });

      const results = await source.search('tempo');
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].url).toContain('lacuerda.net/tabs/');
    });

    it('should extract song content correctly', async () => {
      const mockHtml = '<html><body><h1>Song Title</h1><h2>Artist Name</h2><pre>Chords and Lyrics</pre></body></html>';
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        text: () => Promise.resolve(mockHtml),
      });

      const song = await source.getSong('some-url');
      expect(song.title).toBe('Song Title');
      expect(song.artist).toBe('Artist Name');
      expect(song.lyrics).toBe('Chords and Lyrics');
    });
  });

  describe('UltimateGuitarSource', () => {
    const source = new UltimateGuitarSource();

    it('should parse search results from JSON data-content', async () => {
      const mockData = {
        store: {
          page: {
            data: {
              results: [
                { type: 'tab', song_name: 'Yellow', artist_name: 'Coldplay', tab_url: 'https://ug.com/tab1' }
              ]
            }
          }
        }
      };
      const mockHtml = `<html><body><div class="js-store" data-content='${JSON.stringify(mockData)}'></div></body></html>`;
      
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        text: () => Promise.resolve(mockHtml),
      });

      const results = await source.search('yellow');
      expect(results.length).toBe(1);
      expect(results[0].title).toBe('Yellow');
      expect(results[0].artist).toBe('Coldplay');
    });
  });

  describe('CifrasSource', () => {
    const source = new CifrasSource();

    it('should parse search results correctly', async () => {
      const mockHtml = `
        <div class="search-result">
          <div class="item">
            <a href="/artist/song">
              <span class="title">Song Title</span>
              <span class="artist">Artist Name</span>
            </a>
          </div>
        </div>
      `;
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        text: () => Promise.resolve(mockHtml),
      });

      const results = await source.search('test');
      expect(results.length).toBe(1);
      expect(results[0].title).toBe('Song Title');
      expect(results[0].artist).toBe('Artist Name');
    });
  });
});
