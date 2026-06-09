import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/ultimate_guitar_source.dart';
import 'package:acorde/core/sources/cifras_source.dart';

void main() {
  group('UltimateGuitarSource', () {
    late UltimateGuitarSource source;
    String mockResponse = '';

    Future<String> mockFetchHtml(String url) async {
      return mockResponse;
    }

    setUp(() {
      source = UltimateGuitarSource(fetchHtmlFn: mockFetchHtml);
    });

    test('should parse search results from JSON data-content', () async {
      final mockData = {
        'store': {
          'page': {
            'data': {
              'results': [
                {
                  'type': 'tab',
                  'song_name': 'Yellow',
                  'artist_name': 'Coldplay',
                  'tab_url': 'https://www.ultimate-guitar.com/tab/12345',
                  'type_name': 'Chords',
                  'rating': '4.8',
                  'is_pro': false,
                },
              ],
            },
          },
        },
      };

      final mockHtml =
          '<html><body><div class="js-store" data-content=\'${jsonEncode(mockData)}\'></div></body></html>';
      mockResponse = mockHtml;

      final results = await source.search('yellow');
      expect(results.length, equals(1));
      expect(results[0].title, equals('Yellow'));
      expect(results[0].artist, equals('Coldplay'));
      expect(
        results[0].url,
        equals('https://www.ultimate-guitar.com/tab/12345'),
      );
    });
  });

  group('CifrasSource', () {
    late CifrasSource source;
    String mockResponse = '';

    Future<String> mockFetchHtml(String url) async {
      return mockResponse;
    }

    setUp(() {
      source = CifrasSource(fetchHtmlFn: mockFetchHtml);
    });

    test('should parse search results correctly', () async {
      const mockHtml = '''
        <div class="search-result">
          <div class="item">
            <a href="/artist/song">
              <span class="title">Song Title</span>
              <span class="artist">Artist Name</span>
            </a>
          </div>
        </div>
      ''';
      mockResponse = mockHtml;

      final results = await source.search('test');
      expect(results.length, equals(1));
      expect(results[0].title, equals('Song Title'));
      expect(results[0].artist, equals('Artist Name'));
    });
  });
}
