import { CifraclubSource } from '../sources/CifraclubSource';

// Mocking global fetch for testing
global.fetch = jest.fn();

describe('CifraclubSource', () => {
  let source: CifraclubSource;

  beforeEach(() => {
    source = new CifraclubSource();
    jest.clearAllMocks();
  });

  describe('search', () => {
    it('should parse search results correctly from links', async () => {
      const mockHtml = `
        <html>
          <body>
            <a href="/legiao-urbana/tempo-perdido/">Tempo Perdido - Legião Urbana</a>
            <a href="/legiao-urbana/pais-e-filhos/">Pais e Filhos - Legião Urbana</a>
            <a href="/contato/">Contato</a>
            <a href="/top-musicas/">Top Músicas</a>
          </body>
        </html>
      `;
      
      (global.fetch as jest.Mock).mockResolvedValue({
        text: () => Promise.resolve(mockHtml),
      });

      const results = await source.search('legiao');
      
      expect(results.length).toBeGreaterThan(0);
      expect(results[0].title).toBe('Tempo Perdido - Legião Urbana');
      expect(results[0].artist).toBe('legiao-urbana');
      expect(results[0].url).toBe('https://www.cifraclub.com/legiao-urbana/tempo-perdido/');
    });
  });

  describe('getSong', () => {
    it('should extract title, artist, and content correctly', async () => {
      const mockHtml = `
        <html>
          <body>
            <h1 class="t1">Tempo Perdido</h1>
            <h2 class="t3"><a href="/legiao-urbana/">Legião Urbana</a></h2>
            <div class="cifra-column">
              <pre>
                [Intro] C  Am7  Bm  Em
                
                C             Am7
                Todos os dias quando acordo
                Bm            Em
                Não tenho mais o tempo que passou
              </pre>
            </div>
          </body>
        </html>
      `;

      (global.fetch as jest.Mock).mockResolvedValue({
        text: () => Promise.resolve(mockHtml),
      });

      const song = await source.getSong('https://www.cifraclub.com/legiao-urbana/tempo-perdido/');
      
      expect(song.title).toBe('Tempo Perdido');
      expect(song.artist).toBe('Legião Urbana');
      expect(song.lyrics).toContain('Todos os dias quando acordo');
      expect(song.lyrics).toContain('[Intro] C  Am7  Bm  Em');
    });

    it('should handle missing artist or title gracefully', async () => {
      const mockHtml = `
        <html>
          <body>
            <h1>Minimal Song</h1>
            <div id="ct_cifra">
              <pre>Only lyrics here</pre>
            </div>
          </body>
        </html>
      `;

      (global.fetch as jest.Mock).mockResolvedValue({
        text: () => Promise.resolve(mockHtml),
      });

      const song = await source.getSong('https://www.cifraclub.com/minimal/');
      
      expect(song.title).toBe('Minimal Song');
      expect(song.artist).toBe('Unknown Artist');
      expect(song.lyrics).toBe('Only lyrics here');
    });

    it('should handle simplified versions if the URL contains /simplificada/', async () => {
      const mockHtml = `
        <html>
          <body>
            <h1 class="t1">Tempo Perdido (Simplificada)</h1>
            <h2 class="t3">Legião Urbana</h2>
            <div class="cifra-column">
              <pre>Simplified Chords: C G Am F</pre>
            </div>
          </body>
        </html>
      `;

      (global.fetch as jest.Mock).mockResolvedValue({
        text: () => Promise.resolve(mockHtml),
      });

      const song = await source.getSong('https://www.cifraclub.com/legiao-urbana/tempo-perdido/simplificada/');
      
      expect(song.title).toContain('Simplificada');
      expect(song.lyrics).toContain('Simplified Chords');
    });

    const songTestCases = [
      { artist: 'almir-sater', song: 'tocando-em-frente', title: 'Tocando em Frente', artistName: 'Almir Sater' },
      { artist: 'coldplay', song: 'yellow', title: 'Yellow', artistName: 'Coldplay' },
      { artist: 'the-beatles', song: 'let-it-be', title: 'Let It Be', artistName: 'The Beatles' },
      { artist: 'marilia-mendonca', song: 'infiel', title: 'Infiel', artistName: 'Marília Mendonça' },
      { artist: 'nando-reis', song: 'all-star', title: 'All Star', artistName: 'Nando Reis' },
      { artist: 'charlie-brown-jr', song: 'ceu-azul', title: 'Céu Azul', artistName: 'Charlie Brown Jr.' },
      { artist: 'djavan', song: 'oceano', title: 'Oceano', artistName: 'Djavan' },
      { artist: 'caetano-veloso', song: 'sozinho', title: 'Sozinho', artistName: 'Caetano Veloso' },
      { artist: 'queen', song: 'bohemian-rhapsody', title: 'Bohemian Rhapsody', artistName: 'Queen' },
      { artist: 'oasis', song: 'wonderwall', title: 'Wonderwall', artistName: 'Oasis' },
      { artist: 'skank', song: 'resposta', title: 'Resposta', artistName: 'Skank' },
      { artist: 'ana-vitoria', song: 'trevo', title: 'Trevo (Tu)', artistName: 'Ana Vitória' },
      { artist: 'gilberto-gil', song: 'a-paz', title: 'A Paz', artistName: 'Gilberto Gil' },
      { artist: 'elis-regina', song: 'como-nossos-pais', title: 'Como Nossos Pais', artistName: 'Elis Regina' },
      { artist: 'tim-maia', song: 'gostava-tanto-de-voce', title: 'Gostava Tanto De Você', artistName: 'Tim Maia' },
      { artist: 'jorge-mateus', song: 'sosseguei', title: 'Sosseguei', artistName: 'Jorge & Mateus' },
      { artist: 'henrique-juliano', song: 'liberdade-provisoria', title: 'Liberdade Provisória', artistName: 'Henrique & Juliano' },
      { artist: 'gusttavo-lima', song: 'balada', title: 'Balada', artistName: 'Gusttavo Lima' },
      { artist: 'luan-santana', song: 'morena', title: 'Morena', artistName: 'Luan Santana' },
      { artist: 'pink-floyd', song: 'wish-you-were-here', title: 'Wish You Were Here', artistName: 'Pink Floyd' },
    ];

    test.each(songTestCases)('should correctly parse $title by $artistName', async ({ artist, song, title, artistName }) => {
      const url = `https://www.cifraclub.com/${artist}/${song}/`;
      const mockHtml = `
        <html>
          <body>
            <h1 class="t1">${title}</h1>
            <h2 class="t3"><a href="/${artist}/">${artistName}</a></h2>
            <div class="cifra-column">
              <pre>Chords and lyrics for ${title}...</pre>
            </div>
          </body>
        </html>
      `;

      (global.fetch as jest.Mock).mockResolvedValue({
        text: () => Promise.resolve(mockHtml),
      });

      const result = await source.getSong(url);
      
      expect(result.title).toBe(title);
      expect(result.artist).toBe(artistName);
      expect(result.lyrics).toContain(`Chords and lyrics for ${title}`);
    });
  });
});
