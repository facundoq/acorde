import { CifraclubSource } from './sources/CifraclubSource';
import { LaCuerdaSource } from './sources/LaCuerdaSource';
import { UltimateGuitarSource } from './sources/UltimateGuitarSource';
import { CifrasSource } from './sources/CifrasSource';

async function testSources() {
  const sources = [
    new CifraclubSource(),
    new LaCuerdaSource(),
    new UltimateGuitarSource(),
    new CifrasSource()
  ];

  for (const source of sources) {
    console.log(`\n--- Testing ${source.name} ---`);
    try {
      const results = await source.search('tempo');
      console.log(`Results found: ${results.length}`);
      if (results.length > 0) {
        console.log(`Top result: ${results[0].title} - ${results[0].artist}`);
        console.log(`URL: ${results[0].url}`);
      }
    } catch (e: any) {
      console.error(`Error searching ${source.name}:`, e.message);
    }
  }
}

testSources();
