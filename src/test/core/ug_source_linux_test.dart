// test/core/ug_source_linux_test.dart
//
// Verifies that UltimateGuitarSource correctly parses the HTML that a
// headless Chromium subprocess would return on Linux.
//
// UltimateGuitar embeds all data as JSON inside:
//   <div class="js-store" data-content="...">
//
// Because the JSON is server-side rendered in the initial HTML, the headless
// browser (or HTTP fetch when it works) returns this element fully populated.
// These tests use realistic HTML/JSON snapshots matching the real site structure.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/ultimate_guitar_source.dart';
import 'package:acorde/core/models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String buildSearchHtml({required List<Map<String, dynamic>> results}) {
  final data = {
    'store': {
      'page': {
        'data': {'results': results},
      },
    },
  };
  // data-content attribute uses HTML-encoded single quotes on the real site;
  // our parser uses htmlparser2 which handles both. Use double-quote JSON.
  final jsonStr = jsonEncode(data).replaceAll("'", '&#39;');
  return '''
<!DOCTYPE html>
<html>
<head><title>Ultimate Guitar</title></head>
<body>
  <div class="js-store" data-content='$jsonStr'></div>
</body>
</html>
''';
}

String buildSongHtml({
  required String songName,
  required String artistName,
  required String content,
  String? type,
  double? rating,
}) {
  final tabData = {
    'song_name': songName,
    'artist_name': artistName,
    'type_name': type ?? 'Chords',
    'rating': rating?.toString() ?? '4.5',
  };
  final data = {
    'store': {
      'page': {
        'data': {
          'tab': tabData,
          'tab_view': {
            'wiki_tab': {'content': content},
          },
        },
      },
    },
  };
  final jsonStr = jsonEncode(data).replaceAll("'", '&#39;');
  return '''
<!DOCTYPE html>
<html>
<head><title>$songName Chords by $artistName</title></head>
<body>
  <div class="js-store" data-content='$jsonStr'></div>
</body>
</html>
''';
}

// Tab content in UG format (what a headless browser would return)
const _yellowContent = '''
[Intro]
[ch]G[/ch] - [ch]Bm[/ch] - [ch]C[/ch] - [ch]G[/ch]

[Verse 1]
[tab][ch]G[/ch]                   [ch]Bm[/ch]
In the town where I was born
         [ch]C[/ch]                [ch]G[/ch]
Lived a man who sailed to sea[/tab]

[Chorus]
[tab][ch]G[/ch]             [ch]Bm[/ch]
We all live in a yellow submarine
[ch]C[/ch]                [ch]G[/ch]
Yellow submarine, yellow submarine[/tab]
''';

const _bohemianContent = '''
[Intro]
[ch]Bb[/ch] - [ch]Gm[/ch] - [ch]Cm[/ch] - [ch]F[/ch]

[Verse]
[tab][ch]Bb[/ch]             [ch]Gm[/ch]
Is this the real life?
         [ch]Cm[/ch]              [ch]F[/ch]
Is this just fantasy?[/tab]
''';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('UltimateGuitarSource (Linux headless-Chromium HTML output)', () {
    late UltimateGuitarSource source;
    late String Function(String url) nextHtml;

    setUp(() {
      source = UltimateGuitarSource(fetchHtmlFn: (url) async => nextHtml(url));
    });

    // -----------------------------------------------------------------------
    // search()
    // -----------------------------------------------------------------------
    group('search()', () {
      test('parses multiple results from js-store JSON', () async {
        nextHtml = (_) => buildSearchHtml(
          results: [
            {
              'song_name': 'Yellow Submarine',
              'artist_name': 'The Beatles',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-46953',
              'type_name': 'Chords',
              'rating': '4.8',
              'is_pro': false,
            },
            {
              'song_name': 'Yellow',
              'artist_name': 'Coldplay',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/coldplay/yellow-chords-12345',
              'type_name': 'Chords',
              'rating': '4.6',
              'is_pro': false,
            },
          ],
        );

        final results = await source.search('yellow');

        expect(results.length, equals(2));
        expect(results[0].title, equals('Yellow Submarine'));
        expect(results[0].artist, equals('The Beatles'));
        expect(results[0].source, equals('ultimateguitar'));
        expect(results[1].title, equals('Yellow'));
        expect(results[1].artist, equals('Coldplay'));
      });

      test('filters out PRO / Official tabs', () async {
        nextHtml = (_) => buildSearchHtml(
          results: [
            {
              'song_name': 'Bohemian Rhapsody',
              'artist_name': 'Queen',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/queen/bohemian-rhapsody-chords-1234',
              'type_name': 'Chords',
              'is_pro': false,
            },
            {
              'song_name': 'Bohemian Rhapsody Pro',
              'artist_name': 'Queen',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/queen/bohemian-rhapsody-pro-5678',
              'type_name': 'Official',
              'is_pro': true,
            },
            {
              'song_name': 'Bohemian Rhapsody Guitar Pro',
              'artist_name': 'Queen',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/queen/bohemian-rhapsody-gp-9999',
              'type_name': 'Guitar Pro',
              'is_pro': false,
            },
            {
              'song_name': 'Bohemian Rhapsody Official Web',
              'artist_name': 'Queen',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/queen/bohemian-rhapsody-official-1111',
              'type_name': 'Chords',
              'is_official': true,
            },
            {
              'song_name': 'Bohemian Rhapsody Marketing Pro',
              'artist_name': 'Queen',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/queen/bohemian-rhapsody-chords-2222',
              'type_name': 'Chords',
              'marketing_type': 'pro',
            },
            {
              'song_name': 'Professional Widow',
              'artist_name': 'Tori Amos',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/tori-amos/professional-widow-chords-12345',
              'type_name': 'Chords',
              'is_pro': false,
            },
          ],
        );

        final results = await source.search('bohemian');

        expect(results.length, equals(2));
        expect(results[0].title, equals('Bohemian Rhapsody'));
        expect(results[0].instrument, equals('Chords'));
        expect(results[1].title, equals('Professional Widow'));
        expect(results[1].artist, equals('Tori Amos'));
      });

      test('returns empty list when results array is empty', () async {
        nextHtml = (_) => buildSearchHtml(results: []);
        final results = await source.search('xyznotexist123');
        expect(results, isEmpty);
      });

      test('returns empty list when page has no js-store element', () async {
        nextHtml = (_) => '<html><body><h1>404 Not Found</h1></body></html>';
        final results = await source.search('anysong');
        expect(results, isEmpty);
      });

      test('caps results at 20', () async {
        final manyResults = List.generate(
          30,
          (i) => {
            'song_name': 'Song $i',
            'artist_name': 'Artist',
            'tab_url':
                'https://www.ultimate-guitar.com/tab/artist/song-$i-chords-$i',
            'type_name': 'Chords',
            'is_pro': false,
          },
        );
        nextHtml = (_) => buildSearchHtml(results: manyResults);

        final results = await source.search('song');
        expect(results.length, equals(20));
      });

      test('parses rating as double when present', () async {
        nextHtml = (_) => buildSearchHtml(
          results: [
            {
              'song_name': 'Wonderwall',
              'artist_name': 'Oasis',
              'tab_url':
                  'https://www.ultimate-guitar.com/tab/oasis/wonderwall-chords-1',
              'type_name': 'Chords',
              'rating': '4.9',
              'is_pro': false,
            },
          ],
        );

        final results = await source.search('wonderwall');
        expect(results.first.rating, closeTo(4.9, 0.001));
      });
    });

    // -----------------------------------------------------------------------
    // getSong()
    // -----------------------------------------------------------------------
    group('getSong()', () {
      test('parses title, artist and UG-format content', () async {
        nextHtml = (_) => buildSongHtml(
          songName: 'Yellow Submarine',
          artistName: 'The Beatles',
          content: _yellowContent,
          type: 'Chords',
          rating: 4.8,
        );

        final song = await source.getSong(
          'https://www.ultimate-guitar.com/tab/the-beatles/yellow-submarine-chords-46953',
        );

        expect(song.title, equals('Yellow Submarine'));
        expect(song.artist, equals('The Beatles'));
        expect(song.lyrics, contains('[ch]G[/ch]'));
        expect(song.lyrics, contains('[tab]'));
        expect(song.source, equals('ultimateguitar'));
      });

      test('parses Bohemian Rhapsody content', () async {
        nextHtml = (_) => buildSongHtml(
          songName: 'Bohemian Rhapsody',
          artistName: 'Queen',
          content: _bohemianContent,
        );

        final song = await source.getSong(
          'https://www.ultimate-guitar.com/tab/queen/bohemian-rhapsody-chords-1234',
        );

        expect(song.title, equals('Bohemian Rhapsody'));
        expect(song.artist, equals('Queen'));
        expect(song.lyrics, contains('Is this the real life?'));
        expect(song.lyrics, contains('[ch]Bb[/ch]'));
      });

      test(
        'returns SongContent with fallback values on empty js-store',
        () async {
          nextHtml = (_) => '<html><body><h1>Error</h1></body></html>';

          final song = await source.getSong(
            'https://www.ultimate-guitar.com/tab/artist/song-1',
          );

          // Should not throw — returns a SongContent with error indication
          expect(song, isA<SongContent>());
          expect(song.title, isNotEmpty);
        },
      );

      test('throws on Cloudflare verification page', () async {
        nextHtml = (_) =>
            '<html><body><h1>Just a moment...</h1><div id="challenge-running"></div></body></html>';

        expect(
          () => source.getSong(
            'https://www.ultimate-guitar.com/tab/artist/song-1',
          ),
          throwsException,
        );
      });
    });
  });
}
