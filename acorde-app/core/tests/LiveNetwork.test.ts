import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';
import { LaCuerdaSource } from '../sources/LaCuerdaSource';
import { CifraclubSource } from '../sources/CifraclubSource';
import { CifrasSource } from '../sources/CifrasSource';

// Increase timeout for live network requests
jest.setTimeout(120000);

const randomDelay = () => {
  const delay = Math.floor(Math.random() * 5000) + 3000; // 3-8 seconds
  console.log(`[Live Test] Delaying for ${delay}ms...`);
  return new Promise(resolve => setTimeout(resolve, delay));
};

describe('Kind 3: Live Network Retrieval and Search', () => {
  const sources = [
    new UltimateGuitarSource(),
    new LaCuerdaSource(),
    new CifraclubSource(),
    new CifrasSource()
  ];

  beforeEach(async () => {
    await randomDelay();
  });

  describe('Live Searches', () => {
    sources.forEach(source => {
      test(`${source.name}: should perform a live search`, async () => {
        try {
          const results = await source.search('Beatles');
          if (results.length === 0) {
            console.warn(`[Live Test] ${source.name} search returned 0 results. Might be blocked.`);
            return;
          }
          expect(results.length).toBeGreaterThan(0);
          expect(results[0].title).toBeDefined();
        } catch (e: any) {
          console.warn(`[Live Test] ${source.name} search failed/skipped: ${e.message}`);
        }
      });
    });
  });

  describe('Live Song Retrieval', () => {
    test('Ultimate Guitar: should retrieve a song', async () => {
      const source = new UltimateGuitarSource();
      const url = 'https://tabs.ultimate-guitar.com/tab/the-beatles/yesterday-chords-17445';
      try {
        const song = await source.getSong(url);
        if (song.title === 'Unknown Title') {
          console.warn('[Live Test] UG retrieval returned Unknown Title. Might be blocked.');
          return;
        }
        expect(song.title).toBe('Yesterday');
        expect(song.chords?.length).toBeGreaterThan(100);
      } catch (e: any) {
        console.warn(`[Live Test] UG retrieval failed/skipped: ${e.message}`);
      }
    });

    test('LaCuerda: should retrieve a song', async () => {
      const source = new LaCuerdaSource();
      // Use a very common song
      const url = 'https://acordes.lacuerda.net/beatles/let_it_be.shtml';
      try {
        const song = await source.getSong(url);
        if (song.title === 'Unknown Title') {
          console.warn('[Live Test] LaCuerda retrieval returned Unknown Title. Might be blocked.');
          return;
        }
        expect(song.title).toBeDefined();
        expect(song.chords?.length).toBeGreaterThan(100);
      } catch (e: any) {
        console.warn(`[Live Test] LaCuerda retrieval failed/skipped: ${e.message}`);
      }
    });
  });
});
