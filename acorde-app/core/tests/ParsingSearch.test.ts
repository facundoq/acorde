import fs from 'fs';
import path from 'path';
import { UltimateGuitarSource } from '../sources/UltimateGuitarSource';
import { LaCuerdaSource } from '../sources/LaCuerdaSource';

// Mock fetchHtml to return local file content
jest.mock('../fetcher', () => ({
  fetchHtml: jest.fn()
}));

import { fetchHtml } from '../fetcher';

describe('Kind 2: Stored Search HTML Parsing', () => {
  const ugSource = new UltimateGuitarSource();
  const lcSource = new LaCuerdaSource();
  const baseSamplesDir = path.join(__dirname, 'samples', 'search');

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Ultimate Guitar Searches', () => {
    const ugSamplesDir = path.join(baseSamplesDir, 'ug');
    if (fs.existsSync(ugSamplesDir)) {
      const samples = fs.readdirSync(ugSamplesDir).filter(f => f.endsWith('.html'));

      samples.forEach(filename => {
        test(`should parse UG search: ${filename}`, async () => {
          const html = fs.readFileSync(path.join(ugSamplesDir, filename), 'utf8');
          (fetchHtml as jest.Mock).mockResolvedValue(html);

          const results = await ugSource.search('fake query');
          
          expect(results.length).toBeGreaterThan(0);
          expect(results[0].title).toBeDefined();
          expect(results[0].artist).toBeDefined();
          expect(results[0].url).toContain('ultimate-guitar.com/tab/');
        });
      });
    }
  });

  describe('LaCuerda Searches', () => {
    const lcSamplesDir = path.join(baseSamplesDir, 'lacuerda');
    if (fs.existsSync(lcSamplesDir)) {
      const samples = fs.readdirSync(lcSamplesDir).filter(f => f.endsWith('.html'));

      samples.forEach(filename => {
        test(`should parse LaCuerda search: ${filename}`, async () => {
          const html = fs.readFileSync(path.join(lcSamplesDir, filename), 'utf8');
          (fetchHtml as jest.Mock).mockResolvedValue(html);

          const results = await lcSource.search('fake query');
          
          expect(results.length).toBeGreaterThan(0);
          expect(results[0].title).toBeDefined();
          expect(results[0].url).toBeDefined();
        });
      });
    }
  });
});
