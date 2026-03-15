import { CifraclubSource } from '../sources/CifraclubSource';
import { LaCuerdaSource } from '../sources/LaCuerdaSource';
import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';
import { CifrasSource } from '../sources/CifrasSource';

// Increase timeout for live network requests
jest.setTimeout(30000);

describe('Live Tab Retrieval', () => {
  test('Ultimate Guitar Retrieval', async () => {
    const source = new UltimateGuitarSource();
    const song = await source.getSong('https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-1047118');
    expect(song.title).toBeDefined();
    expect(song.chords?.length).toBeGreaterThan(100);
  });

  test('Cifra Club Retrieval', async () => {
    const source = new CifraclubSource();
    const song = await source.getSong('https://www.cifraclub.com.br/the-beatles/yellow-submarine/');
    expect(song.title).toBeDefined();
    expect(song.chords?.length).toBeGreaterThan(100);
  });

  test('La Cuerda Retrieval', async () => {
    const source = new LaCuerdaSource();
    const song = await source.getSong('https://lacuerda.net/tabs/b/beatles/yellow_submarine.shtml');
    expect(song.title).toBeDefined();
    expect(song.chords?.length).toBeGreaterThan(100);
  });

  test('Cifras Retrieval', async () => {
    const source = new CifrasSource();
    const song = await source.getSong('https://www.cifras.com.br/cifra/the-beatles/yellow-submarine');
    expect(song.title).toBeDefined();
    expect(song.chords?.length).toBeGreaterThan(100);
  });
});
