import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/cifraclub_source.dart';

void main() {
  group('CifraclubSource', () {
    late CifraclubSource source;
    String mockResponse = '';

    Future<String> mockFetchHtml(String url) async {
      return mockResponse;
    }

    setUp(() {
      source = CifraclubSource(fetchHtmlFn: mockFetchHtml);
    });

    group('search', () {
      test('should parse search results correctly from links', () async {
        const mockHtml = '''
          <html>
            <body>
              <a href="/legiao-urbana/tempo-perdido/">Tempo Perdido - Legião Urbana</a>
              <a href="/legiao-urbana/pais-e-filhos/">Pais e Filhos - Legião Urbana</a>
              <a href="/contato/">Contato</a>
              <a href="/top-musicas/">Top Músicas</a>
            </body>
          </html>
        ''';
        mockResponse = mockHtml;

        final results = await source.search('legiao');

        expect(results.length, greaterThan(0));
        expect(results[0].title, equals('Tempo Perdido - Legião Urbana'));
        expect(results[0].artist, equals('legiao-urbana'));
        expect(
          results[0].url,
          equals('https://www.cifraclub.com.br/legiao-urbana/tempo-perdido/'),
        );
      });
    });

    group('getSong', () {
      test('should extract title, artist, and content correctly', () async {
        const mockHtml = '''
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
        ''';
        mockResponse = mockHtml;

        final song = await source.getSong(
          'https://www.cifraclub.com/legiao-urbana/tempo-perdido/',
        );

        expect(song.title, equals('Tempo Perdido'));
        expect(song.artist, equals('Legião Urbana'));
        expect(song.lyrics, contains('Todos os dias quando acordo'));
        expect(song.lyrics, contains('[Intro] C  Am7  Bm  Em'));
      });

      test('should handle missing artist or title gracefully', () async {
        const mockHtml = '''
          <html>
            <body>
              <h1>Minimal Song</h1>
              <div id="ct_cifra">
                <pre>Only lyrics here</pre>
              </div>
            </body>
          </html>
        ''';
        mockResponse = mockHtml;

        final song = await source.getSong('https://www.cifraclub.com/minimal/');

        expect(song.title, equals('Minimal Song'));
        expect(song.artist, equals('Unknown Artist'));
        expect(song.lyrics, equals('Only lyrics here'));
      });

      test(
        'should handle simplified versions if the URL contains /simplificada/',
        () async {
          const mockHtml = '''
          <html>
            <body>
              <h1 class="t1">Tempo Perdido (Simplificada)</h1>
              <h2 class="t3">Legião Urbana</h2>
              <div class="cifra-column">
                <pre>Simplified Chords: C G Am F</pre>
              </div>
            </body>
          </html>
        ''';
          mockResponse = mockHtml;

          final song = await source.getSong(
            'https://www.cifraclub.com/legiao-urbana/tempo-perdido/simplificada/',
          );

          expect(song.title, contains('Simplificada'));
          expect(song.lyrics, contains('Simplified Chords'));
        },
      );

      final songTestCases = [
        {
          'artist': 'almir-sater',
          'song': 'tocando-em-frente',
          'title': 'Tocando em Frente',
          'artistName': 'Almir Sater',
        },
        {
          'artist': 'coldplay',
          'song': 'yellow',
          'title': 'Yellow',
          'artistName': 'Coldplay',
        },
        {
          'artist': 'the-beatles',
          'song': 'let-it-be',
          'title': 'Let It Be',
          'artistName': 'The Beatles',
        },
        {
          'artist': 'marilia-mendonca',
          'song': 'infiel',
          'title': 'Infiel',
          'artistName': 'Marília Mendonça',
        },
        {
          'artist': 'nando-reis',
          'song': 'all-star',
          'title': 'All Star',
          'artistName': 'Nando Reis',
        },
        {
          'artist': 'charlie-brown-jr',
          'song': 'ceu-azul',
          'title': 'Céu Azul',
          'artistName': 'Charlie Brown Jr.',
        },
        {
          'artist': 'djavan',
          'song': 'oceano',
          'title': 'Oceano',
          'artistName': 'Djavan',
        },
        {
          'artist': 'caetano-veloso',
          'song': 'sozinho',
          'title': 'Sozinho',
          'artistName': 'Caetano Veloso',
        },
        {
          'artist': 'queen',
          'song': 'bohemian-rhapsody',
          'title': 'Bohemian Rhapsody',
          'artistName': 'Queen',
        },
        {
          'artist': 'oasis',
          'song': 'wonderwall',
          'title': 'Wonderwall',
          'artistName': 'Oasis',
        },
        {
          'artist': 'skank',
          'song': 'resposta',
          'title': 'Resposta',
          'artistName': 'Skank',
        },
        {
          'artist': 'ana-vitoria',
          'song': 'trevo',
          'title': 'Trevo (Tu)',
          'artistName': 'Ana Vitória',
        },
        {
          'artist': 'gilberto-gil',
          'song': 'a-paz',
          'title': 'A Paz',
          'artistName': 'Gilberto Gil',
        },
        {
          'artist': 'elis-regina',
          'song': 'como-nossos-pais',
          'title': 'Como Nossos Pais',
          'artistName': 'Elis Regina',
        },
        {
          'artist': 'tim-maia',
          'song': 'gostava-tanto-de-voce',
          'title': 'Gostava Tanto De Você',
          'artistName': 'Tim Maia',
        },
        {
          'artist': 'jorge-mateus',
          'song': 'sosseguei',
          'title': 'Sosseguei',
          'artistName': 'Jorge & Mateus',
        },
        {
          'artist': 'henrique-juliano',
          'song': 'liberdade-provisoria',
          'title': 'Liberdade Provisória',
          'artistName': 'Henrique & Juliano',
        },
        {
          'artist': 'gusttavo-lima',
          'song': 'balada',
          'title': 'Balada',
          'artistName': 'Gusttavo Lima',
        },
        {
          'artist': 'luan-santana',
          'song': 'morena',
          'title': 'Morena',
          'artistName': 'Luan Santana',
        },
        {
          'artist': 'pink-floyd',
          'song': 'wish-you-were-here',
          'title': 'Wish You Were Here',
          'artistName': 'Pink Floyd',
        },
      ];

      for (final tc in songTestCases) {
        test(
          'should correctly parse ${tc['title']} by ${tc['artistName']}',
          () async {
            final url =
                'https://www.cifraclub.com/${tc['artist']}/${tc['song']}/';
            final mockHtml =
                '''
            <html>
              <body>
                <h1 class="t1">${tc['title']}</h1>
                <h2 class="t3"><a href="/${tc['artist']}/">${tc['artistName']}</a></h2>
                <div class="cifra-column">
                  <pre>Chords and lyrics for ${tc['title']}...</pre>
                </div>
              </body>
            </html>
          ''';
            mockResponse = mockHtml;

            final result = await source.getSong(url);

            expect(result.title, equals(tc['title']));
            expect(result.artist, equals(tc['artistName']));
            expect(
              result.lyrics,
              contains('Chords and lyrics for ${tc['title']}'),
            );
          },
        );
      }
    });
  });
}
