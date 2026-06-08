import fs from 'fs';
import path from 'path';
import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';
import { LaCuerdaSource } from '../sources/LaCuerdaSource';

// Mock fetchHtml to return local file content
jest.mock('../fetcher', () => ({
  fetchHtml: jest.fn()
}));

import { fetchHtml } from '../fetcher';

describe('Kind 1: Stored Song HTML Parsing', () => {
  const ugSource = new UltimateGuitarSource();
  const lcSource = new LaCuerdaSource();
  const baseSamplesDir = path.join(__dirname, 'samples', 'song');

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Ultimate Guitar Songs', () => {
    const ugSamplesDir = path.join(baseSamplesDir, 'ug');
    const samples = fs.readdirSync(ugSamplesDir).filter(f => f.endsWith('.html'));

    samples.forEach(filename => {
      test(`should parse UG song: ${filename}`, async () => {
        const html = fs.readFileSync(path.join(ugSamplesDir, filename), 'utf8');
        (fetchHtml as jest.Mock).mockResolvedValue(html);

        const song = await ugSource.getSong(`https://tabs.ultimate-guitar.com/tab/fake/${filename.replace('.html', '')}`);
        
        expect(song.title).not.toBe('Unknown Title');
        expect(song.artist).not.toBe('Unknown Artist');
        expect(song.chords).toBeDefined();
        expect(song.chords?.length).toBeGreaterThan(0);
      });
    });
  });

  describe('LaCuerda Songs', () => {
    const lcSamplesDir = path.join(baseSamplesDir, 'lacuerda');
    const samples = fs.readdirSync(lcSamplesDir).filter(f => f.endsWith('.html'));

    samples.forEach(filename => {
      test(`should parse LaCuerda song: ${filename}`, async () => {
        const html = fs.readFileSync(path.join(lcSamplesDir, filename), 'utf8');
        (fetchHtml as jest.Mock).mockResolvedValue(html);

        const song = await lcSource.getSong(`https://acordes.lacuerda.net/fake/${filename.replace('.html', '')}`);
        
        expect(song.title).not.toBe('Unknown Title');
        expect(song.artist).not.toBe('Unknown Artist');
        expect(song.chords).toBeDefined();
        expect(song.chords?.length).toBeGreaterThan(0);
      });
    });
  });
});
