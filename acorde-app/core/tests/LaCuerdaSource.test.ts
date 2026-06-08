import { LaCuerdaSource } from '../sources/LaCuerdaSource';

global.fetch = jest.fn();

describe('LaCuerdaSource - Advanced Cases', () => {
  let source: LaCuerdaSource;

  beforeEach(() => {
    source = new LaCuerdaSource();
    jest.clearAllMocks();
  });

  const artistOnlyHtml = `
    <ul id=i_main class=s_blist>
      <li><a class=sb href="/dante_spinetta/">Dante Spinetta</a><span>1 canciones</span></li>
      <li><a class=sb href="/luis_a_spinetta/">Luis Alberto Spinetta</a><span>247 canciones</span></li>
    </ul>
  `;

  const songTableHtml = `
    <table id=s_main>
      <tr><td><a href="/spinetta_jade/">Spinetta Jade</a></td><td><ul class=b_main id=b_main0>
        <li id='r000'><a href="javascript:">Alma de diamante</a></li>
      </ul></td></tr>
    </table>
    <script>
      var hds=['spinetta_jade','luis_a_spinetta'];
      var fns=['alma_de_diamante','alma_de_diamante'];
      var NMAX=0;
    </script>
  `;

  test('should parse artist-only results correctly', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      text: () => Promise.resolve(artistOnlyHtml),
    });
    
    const results = await source.search('spinetta');
    expect(results.length).toBe(2);
    expect(results[0].type).toBe('artist');
    expect(results[0].title).toBe('Dante Spinetta');
    expect(results[0].url).toBe('https://acordes.lacuerda.net/dante_spinetta/');
  });

  test('should parse song table with JS links correctly', async () => {
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      text: () => Promise.resolve(songTableHtml),
    });
    
    const results = await source.search('alma de diamante');
    expect(results.length).toBe(1);
    expect(results[0].type).toBe('song');
    expect(results[0].title).toBe('Alma de diamante');
    expect(results[0].artist).toBe('Spinetta Jade');
    expect(results[0].url).toBe('https://acordes.lacuerda.net/spinetta_jade/alma_de_diamante');
  });

  test('should parse artist page correctly when URL is searched', async () => {
    const artistPageHtml = `
      <html>
        <body>
          <h1>Fito Paez</h1>
          <ul id=b_main>
            <li><a href="11_y_6">11 y 6</a></li>
            <li><a href="mariposa_tecknicolor">Mariposa Tecknicolor</a></li>
          </ul>
        </body>
      </html>
    `;
    (global.fetch as jest.Mock).mockResolvedValue({
      ok: true,
      text: () => Promise.resolve(artistPageHtml),
    });

    const results = await source.search('https://acordes.lacuerda.net/fito_paez/');
    expect(results.length).toBe(2);
    expect(results[0].title).toBe('11 y 6');
    expect(results[0].artist).toBe('Fito Paez');
    expect(results[0].url).toBe('https://acordes.lacuerda.net/fito_paez/11_y_6');
  });
});
