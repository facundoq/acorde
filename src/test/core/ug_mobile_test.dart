import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/ultimate_guitar_source.dart';

void main() {
  group('UltimateGuitarSource - Mobile Layout Parsing', () {
    late UltimateGuitarSource source;
    late String searchHtml;
    late String detailHtml;

    setUpAll(() {
      // Read the mobile HTML samples
      searchHtml = File(
        'test/samples/ug_search_mobile.html',
      ).readAsStringSync();
      detailHtml = File(
        'test/samples/ug_detail_mobile.html',
      ).readAsStringSync();
    });

    test('should parse search results from mobile HTML sample', () async {
      source = UltimateGuitarSource(fetchHtmlFn: (url) async => searchHtml);
      final results = await source.search('Rolling stones');

      expect(results, isNotEmpty);
      expect(results.length, greaterThanOrEqualTo(1));

      // Let's verify a specific search result we expect in the mobile search sample
      // (e.g. Wild Horses chords or tabs)
      final hasWildHorses = results.any(
        (r) =>
            r.title.contains('Wild Horses') &&
            r.artist.toLowerCase().contains('stones'),
      );
      expect(
        hasWildHorses,
        isTrue,
        reason: 'Should have found Wild Horses search result',
      );

      final first = results.firstWhere(
        (r) =>
            r.title.contains('Wild Horses') &&
            r.instrument?.toLowerCase() == 'chords',
      );
      expect(first.url, contains('wild-horses'));
      expect(first.instrument?.toLowerCase(), equals('chords'));
    });

    test(
      'should parse song chords/lyrics/title/artist from mobile detail HTML sample',
      () async {
        source = UltimateGuitarSource(fetchHtmlFn: (url) async => detailHtml);
        final song = await source.getSong(
          'https://tabs.ultimate-guitar.com/tab/the-rolling-stones/wild-horses-chords-4017',
        );

        expect(song.title, equals('Wild Horses'));
        expect(song.artist, equals('The Rolling Stones'));
        expect(song.instrument?.toLowerCase(), equals('chords'));
        expect(song.rating, isNotNull);
        expect(song.rating, greaterThan(4.0));
        expect(song.lyrics, contains('[ch]Am7[/ch]'));
        expect(song.lyrics, contains('[ch]G[/ch]'));
      },
    );
  });
}
