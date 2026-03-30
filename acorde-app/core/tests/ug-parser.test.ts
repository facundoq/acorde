import { isUGFormat, parseUGTabs, autoTagChords } from '../ug-parser';

describe('UG Parser', () => {
  describe('isUGFormat', () => {
    it('should detect UG format with [ch] tags', () => {
      const content = 'Wild Horses [ch]G[/ch]';
      expect(isUGFormat(content)).toBe(true);
    });

    it('should detect UG format with [tab] tags', () => {
      const content = '[tab]  G  Am7  [/tab]';
      expect(isUGFormat(content)).toBe(true);
    });

    it('should detect UG format with section headers', () => {
      const content = '[Verse 1]\nChildhood living is easy to do';
      expect(isUGFormat(content)).toBe(true);
    });

    it('should detect UG format with chord-only lines', () => {
      const content = 'C G Am F\nSome lyrics';
      expect(isUGFormat(content)).toBe(true);
    });

    it('should return false for plain text', () => {
      const content = 'Just some regular lyrics without structure';
      expect(isUGFormat(content)).toBe(false);
    });

    it('should handle empty or null content', () => {
      expect(isUGFormat('')).toBe(false);
      expect(isUGFormat(null as any)).toBe(false);
    });
  });

  describe('autoTagChords', () => {
    it('should wrap chords in [ch] tags for chord-only lines', () => {
      const content = 'C G Am F';
      expect(autoTagChords(content)).toBe('[ch]C[/ch] [ch]G[/ch] [ch]Am[/ch] [ch]F[/ch]');
    });

    it('should wrap chords in [ch] tags for chords above lyrics', () => {
      const content = '  C        G\nLyrics here';
      const tagged = autoTagChords(content);
      expect(tagged).toContain('[ch]C[/ch]');
      expect(tagged).toContain('[ch]G[/ch]');
    });

    it('should not wrap headers', () => {
      const content = '[Intro]';
      expect(autoTagChords(content)).toBe('[Intro]');
    });

    it('should handle complex chords like Bb/D', () => {
      const content = 'Bb/D C7sus4';
      expect(autoTagChords(content)).toBe('[ch]Bb/D[/ch] [ch]C7sus4[/ch]');
    });
  });

  describe('parseUGTabs', () => {
    it('should parse [ch] tags correctly', () => {
      const content = 'Some [ch]G[/ch] and [ch]C[/ch] chords';
      const parts = parseUGTabs(content);
      
      expect(parts).toEqual([
        { type: 'text', content: 'Some ' },
        { type: 'chord', content: 'G' },
        { type: 'text', content: ' and ' },
        { type: 'chord', content: 'C' },
        { type: 'text', content: ' chords' }
      ]);
    });

    it('should parse [tab] tags correctly', () => {
      const content = 'Intro:\n[tab]  [ch]G[/ch]  [ch]Am7[/ch]  [/tab]';
      const parts = parseUGTabs(content);
      
      expect(parts).toContainEqual({ type: 'tab', content: '  [ch]G[/ch]  [ch]Am7[/ch]  ' });
    });

    it('should parse section headers correctly', () => {
      const content = '[Intro]\n[Verse 1]\nLyrics';
      const parts = parseUGTabs(content);
      
      expect(parts).toEqual([
        { type: 'header', content: '[Intro]' },
        { type: 'text', content: '\n' },
        { type: 'header', content: '[Verse 1]' },
        { type: 'text', content: '\nLyrics' }
      ]);
    });

    it('should parse complex UG content', () => {
      const content = `[Intro]  | [ch]G[/ch] | [ch]Am7[/ch] |

[Verse]
[tab]  [ch]Bm[/ch]          [ch]G[/ch]      [ch]Bm[/ch]           [ch]G[/ch]
    Childhood living   is easy to do[/tab]`;
      
      const parts = parseUGTabs(content);
      
      expect(parts).toContainEqual({ type: 'header', content: '[Intro]' });
      expect(parts).toContainEqual({ type: 'chord', content: 'G' });
      expect(parts).toContainEqual({ type: 'header', content: '[Verse]' });
      expect(parts).toContainEqual({ type: 'tab', content: '  [ch]Bm[/ch]          [ch]G[/ch]      [ch]Bm[/ch]           [ch]G[/ch]\n    Childhood living   is easy to do' });
    });
  });
});
