import { CifraclubSource } from '../sources/CifraclubSource';
import { LaCuerdaSource } from '../sources/LaCuerdaSource';
import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';
import { CifrasSource } from '../sources/CifrasSource';

global.fetch = jest.fn();

describe('All Providers', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('CifraclubSource', () => {
    const source = new CifraclubSource();

    it('should parse search results from API', async () => {
      const mockData = {
        songs: [
          { url: '/artist/song/', name: 'Song Name', artist: { name: 'Artist Name' } }
        ]
      };
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockData),
        text: () => Promise.resolve(JSON.stringify(mockData)),
      });

      const results = await source.search('test');
      expect(results.length).toBe(1);
      expect(results[0].title).toBe('Song Name');
      expect(results[0].artist).toBe('Artist Name');
    });

    it('should fallback to regex parsing from HTML', async () => {
      // 1. suggestUrl fetch (fails)
      (global.fetch as jest.Mock).mockResolvedValueOnce({ ok: false });
      // 2. suggestUrl retry (succeeds but empty results)
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        text: () => Promise.resolve('{"songs":[]}'),
        json: () => Promise.resolve({ songs: [] }),
      });
      // 3. searchUrl fetch (scraper)
      const mockHtml = `
        <html><body>
          {"name":"Regex Song","url":"/regex-artist/regex-song/"}
        </body></html>
      `;
      (global.fetch as jest.Mock).mockResolvedValueOnce({
        ok: true,
        text: () => Promise.resolve(mockHtml),
      });

      const results = await source.search('test');
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].title).toBe('Regex Song');
      expect(results[0].artist).toBe('regex-artist');
    });
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
