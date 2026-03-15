import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';

jest.setTimeout(30000);

describe('Ultimate Guitar Detail Live Test', () => {
  test('Fetch and parse a specific tab', async () => {
    const source = new UltimateGuitarSource();
    const url = 'https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-1047118';
    
    console.log(`Testing retrieval for: ${url}`);
    try {
      const song = await source.getSong(url);
      console.log('Parsed Song Info:');
      console.log(`  Title: ${song.title}`);
      console.log(`  Artist: ${song.artist}`);
      console.log(`  Content length: ${song.chords?.length}`);
      console.log(`  Content snippet: ${song.chords?.substring(0, 100)}`);
      
      expect(song.title).not.toBe('Unknown Title');
      expect(song.lyrics).not.toBe('Could not parse content');
    } catch (e: any) {
      console.error('Retrieval failed:', e.message);
      throw e;
    }
  });
});
