import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';

// Increase timeout for live network requests
jest.setTimeout(30000);

describe('Live Search Test', () => {
  test('Ultimate Guitar Search for "rolling stones"', async () => {
    const source = new UltimateGuitarSource();
    console.log('Starting live search for "rolling stones"...');
    try {
      const results = await source.search('rolling stones');
      console.log(`Found ${results.length} results.`);
      if (results.length > 0) {
        console.log('First result:', JSON.stringify(results[0], null, 2));
      }
      expect(results.length).toBeGreaterThan(0);
    } catch (e: any) {
      console.error('Search failed:', e.message);
      throw e;
    }
  });
});
