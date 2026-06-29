import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/la_cuerda_source.dart';

void main() {
  group('LaCuerdaSource - Advanced Cases', () {
    late LaCuerdaSource source;
    final Map<String, String> mockUrlResponses = {};
    String mockResponse = '';

    Future<String> mockFetchHtml(String url) async {
      if (mockUrlResponses.containsKey(url)) {
        return mockUrlResponses[url]!;
      }
      return mockResponse;
    }

    setUp(() {
      mockUrlResponses.clear();
      source = LaCuerdaSource(fetchHtmlFn: mockFetchHtml);
    });

    const artistOnlyHtml = '''
      <ul id=i_main class=s_blist>
        <li><a class=sb href="/dante_spinetta/">Dante Spinetta</a><span>1 canciones</span></li>
        <li><a class=sb href="/luis_a_spinetta/">Luis Alberto Spinetta</a><span>247 canciones</span></li>
      </ul>
    ''';

    const songTableHtml = '''
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
    ''';

    test('should parse artist-only results correctly', () async {
      mockResponse = artistOnlyHtml;

      final results = await source.search('spinetta');
      expect(results.length, equals(2));
      expect(results[0].type, equals('artist'));
      expect(results[0].title, equals('Dante Spinetta'));
      expect(
        results[0].url,
        equals('https://acordes.lacuerda.net/dante_spinetta/'),
      );
    });

    test('should parse song table with JS links correctly', () async {
      mockResponse = songTableHtml;

      final results = await source.search('alma de diamante');
      expect(results.length, equals(1));
      expect(results[0].type, equals('song'));
      expect(results[0].title, equals('Alma de diamante'));
      expect(results[0].artist, equals('Spinetta Jade'));
      expect(
        results[0].url,
        equals(
          'https://acordes.lacuerda.net/spinetta_jade/alma_de_diamante.shtml',
        ),
      );
    });

    test('should parse artist page correctly when URL is searched', () async {
      const artistPageHtml = '''
        <html>
          <body>
            <h1>Fito Paez</h1>
            <ul id=b_main>
              <li><a href="11_y_6">11 y 6</a></li>
              <li><a href="mariposa_tecknicolor">Mariposa Tecknicolor</a></li>
            </ul>
          </body>
        </html>
      ''';
      mockResponse = artistPageHtml;

      final results = await source.search(
        'https://acordes.lacuerda.net/fito_paez/',
      );
      expect(results.length, equals(2));
      expect(results[0].title, equals('11 y 6'));
      expect(results[0].artist, equals('Fito Paez'));
      expect(
        results[0].url,
        equals('https://acordes.lacuerda.net/fito_paez/11_y_6.shtml'),
      );
    });

    test(
      'should parse redirected artist search page correctly (canonical link check)',
      () async {
        const redirectedPageHtml = '''
        <html>
          <head>
            <link rel="canonical" href="https://acordes.lacuerda.net/manal/">
          </head>
          <body>
            <h1>Manal</h1>
            <div id="tNav" class="tNav"><div id="rList" class="rList"><ul>
              <li><a href="/jesse_y_joy/dueles">Dueles<em>Jesse y Joy</em></a></li>
            </ul></div></div>
            <ul id="b_main">
              <li><a href="avellaneda_blues">Avellaneda Blues <em>acordes</em></a></li>
              <li><a href="avenida_rivadavia">Avenida Rivadavia <em>acordes</em></a></li>
            </ul>
          </body>
        </html>
      ''';
        mockResponse = redirectedPageHtml;

        final results = await source.search('manal');
        // Should not contain "Dueles" because #rList is ignored
        expect(results.length, equals(2));
        expect(results[0].title, equals('Avellaneda Blues'));
        expect(results[0].artist, equals('Manal'));
        expect(
          results[0].url,
          equals('https://acordes.lacuerda.net/manal/avellaneda_blues.shtml'),
        );
        expect(results[1].title, equals('Avenida Rivadavia'));
        expect(
          results[1].url,
          equals('https://acordes.lacuerda.net/manal/avenida_rivadavia.shtml'),
        );
      },
    );

    test(
      'should resolve and load first version from a versions index page URL',
      () async {
        const indexUrl = 'https://acordes.lacuerda.net/fito_paez/11_y_6';
        const versionUrl =
            'https://acordes.lacuerda.net/fito_paez/11_y_6.shtml';

        const indexHtml = '''
        <html>
          <body>
            <h1>11 y 6</h1>
            <div class="versions">
              <a href="/fito_paez/11_y_6.shtml">Versión 1</a>
              <a href="/fito_paez/11_y_6-2.shtml">Versión 2</a>
            </div>
          </body>
        </html>
      ''';

        const songHtml = '''
        <html>
          <body>
            <h1>11 y 6</h1>
            <h2>Fito Paez</h2>
            <div id="t_body">
              <a href="#">DO</a> <a href="#">SOL</a> <a href="#">LAm</a>
              Llegaste a mi vida...
            </div>
          </body>
        </html>
      ''';

        mockUrlResponses[indexUrl] = indexHtml;
        mockUrlResponses[versionUrl] = songHtml;

        final songContent = await source.getSong(indexUrl);
        expect(songContent.title, equals('11 y 6'));
        expect(songContent.artist, equals('Fito Paez'));
        expect(
          songContent.chords,
          contains('C G Am'),
        ); // Verifying translation Solana
        expect(songContent.url, equals(versionUrl));
      },
    );

    test(
      'should parse versions list page from search and extract rating/instrument info',
      () async {
        const versionsUrl = 'https://acordes.lacuerda.net/fito_paez/11_y_6';
        const indexHtml = '''
        <html>
          <body>
            <div id="r_head">
              <h1>11 y 6 <br><a href="./">Fito Paez</a></h1>
            </div>
            <div class="versions">
              <ul>
                <li id="liElm1">
                  <div class="rtHead">
                    <div class="tipoIcon tiR"></div>
                    <div class="rtLabel"><a href="11_y_6.shtml">Letra y Acordes</a></div>
                    <div id="cal1" class="mCalImg rtMejor"></div>
                  </div>
                </li>
                <li id="liElm2">
                  <div class="rtHead">
                    <div class="tipoIcon tiT"></div>
                    <div class="rtLabel"><a href="11_y_6-2.shtml">Tablatura</a></div>
                    <div id="cal2" class="mCalImg rtBueno"></div>
                  </div>
                </li>
              </ul>
            </div>
          </body>
        </html>
      ''';

        mockResponse = indexHtml;

        final results = await source.search(versionsUrl);
        expect(results.length, equals(2));

        expect(results[0].title, equals('11 y 6 (Letra y Acordes)'));
        expect(results[0].artist, equals('Fito Paez'));
        expect(results[0].instrument, equals('Chords'));
        expect(results[0].rating, equals(5.0));

        expect(results[1].title, equals('11 y 6 (Tablatura)'));
        expect(results[1].artist, equals('Fito Paez'));
        expect(results[1].instrument, equals('Tab'));
        expect(results[1].rating, equals(4.0));
      },
    );
  });
}
