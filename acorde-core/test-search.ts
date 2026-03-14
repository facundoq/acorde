import { CifraclubSource } from './src/sources/CifraclubSource';

async function test() {
  const source = new CifraclubSource();
  console.log('Testing search for "tempo"...');
  try {
    const results = await source.search('tempo');
    console.log('Results count:', results.length);
    results.forEach((r, i) => {
      console.log(`${i + 1}. ${r.title} - ${r.artist} (${r.url})`);
    });
  } catch (error) {
    console.error('Search failed:', error);
  }
}

test();
