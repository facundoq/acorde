import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/ultimate_guitar_source.dart';
import 'package:acorde/core/sources/la_cuerda_source.dart';
import 'package:acorde/core/sources/cifraclub_source.dart';
import 'package:acorde/core/sources/cifras_source.dart';
import 'package:acorde/core/chord_shapes.dart';
import 'package:acorde/core/ug_parser.dart';

void main() {
  group('Real HTML Parsing & Database Verification Tests', () {
    final Map<String, String> ugUrlMapping = {
      'the-beatles-let-it-be.html':
          'https://tabs.ultimate-guitar.com/tab/the-beatles/let-it-be-chords-17427',
      'coldplay-yellow.html':
          'https://tabs.ultimate-guitar.com/tab/coldplay/yellow-chords-114080',
      'oasis-wonderwall.html':
          'https://tabs.ultimate-guitar.com/tab/oasis/wonderwall-chords-39144',
      'queen-bohemian-rhapsody.html':
          'https://tabs.ultimate-guitar.com/tab/queen/bohemian-rhapsody-chords-2632065',
      'pink-floyd-wish-you-were-here.html':
          'https://tabs.ultimate-guitar.com/tab/pink-floyd/wish-you-were-here-chords-44555',
      'radiohead-creep.html':
          'https://tabs.ultimate-guitar.com/tab/radiohead/creep-chords-4169',
      'eagles-hotel-california.html':
          'https://tabs.ultimate-guitar.com/tab/eagles/hotel-california-chords-46190',
      'john-lennon-imagine.html':
          'https://tabs.ultimate-guitar.com/tab/john-lennon/imagine-chords-9306',
      'nirvana-smells-like-teen-spirit.html':
          'https://tabs.ultimate-guitar.com/tab/nirvana/smells-like-teen-spirit-chords-807883',
      'led-zeppelin-stairway-to-heaven.html':
          'https://tabs.ultimate-guitar.com/tab/led-zeppelin/stairway-to-heaven-tabs-9488',
    };

    final Map<String, String> laCuerdaUrlMapping = {
      'fito-paez-11-y-6.html':
          'http://acordes.lacuerda.net/fito_paez/11_y_6.shtml',
      'soda-stereo-de-musica-ligera.html':
          'http://acordes.lacuerda.net/soda_stereo/de_musica_ligera.shtml',
      'charly-garcia-demoliendo-hoteles.html':
          'http://acordes.lacuerda.net/charly_garcia/demoliendo_hoteles.shtml',
      'luis-alberto-spinetta-alma-de-diamante.html':
          'http://acordes.lacuerda.net/luis_a_spinetta/alma_de_diamante.shtml',
      'andres-calamaro-flaca.html':
          'http://acordes.lacuerda.net/andres_calamaro/flaca.shtml',
      'enanitos-verdes-lamento-boliviano.html':
          'http://acordes.lacuerda.net/enanitos/lamento_boliviano.shtml',
      'la-renga-el-revelde.html':
          'http://acordes.lacuerda.net/renga/el_revelde.shtml',
      'los-abuelos-de-la-nada-mil-horas.html':
          'http://acordes.lacuerda.net/abuelos/mil_horas.shtml',
      'fitito-y-fitipaldis-soldadito-marinero.html':
          'http://acordes.lacuerda.net/fito__fitipaldis/soldadito_marinero.shtml',
      'babasonicos-irresponsables.html':
          'http://acordes.lacuerda.net/babasonicos/irresponsables.shtml',
    };

    final Map<String, String> cifraClubUrlMapping = {
      'legiao-urbana-tempo-perdido.html':
          'https://www.cifraclub.com.br/legiao-urbana/tempo-perdido/',
      'almir-sater-tocando-em-frente.html':
          'https://www.cifraclub.com.br/almir-sater/tocando-em-frente/',
      'nando-reis-all-star.html':
          'https://www.cifraclub.com.br/nando-reis/all-star/',
      'charlie-brown-jr-ceu-azul.html':
          'https://www.cifraclub.com.br/charlie-brown-jr/ceu-azul/',
      'djavan-oceano.html': 'https://www.cifraclub.com.br/djavan/oceano/',
      'caetano-veloso-sozinho.html':
          'https://www.cifraclub.com.br/caetano-veloso/sozinho/',
      'skank-resposta.html': 'https://www.cifraclub.com.br/skank/resposta/',
      'elis-regina-como-nossos-pais.html':
          'https://www.cifraclub.com.br/elis-regina/como-nossos-pais/',
      'tim-maia-gostava-tanto-de-voce.html':
          'https://www.cifraclub.com.br/tim-maia/gostava-tanto-de-voce/',
      'marilia-mendonca-infiel.html':
          'https://www.cifraclub.com.br/marilia-mendonca/infiel/',
    };

    final Map<String, String> cifrasUrlMapping = {
      'legiao-urbana-tempo-perdido.html':
          'https://www.cifras.com.br/cifra/legiao-urbana/tempo-perdido',
      'coldplay-yellow.html': 'https://www.cifras.com.br/cifra/coldplay/yellow',
      'the-beatles-let-it-be.html':
          'https://www.cifras.com.br/cifra/the-beatles/let-it-be',
      'nando-reis-all-star.html':
          'https://www.cifras.com.br/cifra/nando-reis/all-star',
      'oasis-wonderwall.html':
          'https://www.cifras.com.br/cifra/oasis/wonderwall',
      'tim-maia-gostava-tanto-de-voce.html':
          'https://www.cifras.com.br/cifra/tim-maia/gostava-tanto-de-voce',
      'raul-seixas-metamorfose-ambulante.html':
          'https://www.cifras.com.br/cifra/raul-seixas/metamorfose-ambulante',
      'charlie-brown-jr-ceu-azul.html':
          'https://www.cifras.com.br/cifra/charlie-brown-jr/ceu-azul',
      'djavan-oceano.html': 'https://www.cifras.com.br/cifra/djavan/oceano',
      'skank-resposta.html': 'https://www.cifras.com.br/cifra/skank/resposta',
    };

    Set<String> extractChords(String content) {
      final tagged = autoTagChords(content);
      final regex = RegExp(r'\[ch\](.*?)\[\/ch\]');
      final Set<String> chords = {};
      for (final match in regex.allMatches(tagged)) {
        final rawChord = match.group(1)!.trim();
        if (rawChord.isNotEmpty) {
          // Normalize chord representation
          chords.add(rawChord);
        }
      }
      return chords;
    }

    void verifySongChords(String songTitle, Set<String> songChords) {
      final List<String> missing = [];
      final chordStartPattern = RegExp(r'^[A-G]');

      for (final chord in songChords) {
        // Simple normalization: strip parentheses/brackets if any, handle common symbols
        var cleanChord = chord
            .replaceAll(RegExp(r'[()\[\]]'), '')
            .replaceAll('min', 'm')
            .trim();

        // Standard chords must start with A-G (uppercase)
        if (!chordStartPattern.hasMatch(cleanChord)) {
          continue; // Ignore non-chords like 'b', 'e', 'x', 'NC', etc.
        }

        // Try lookup using getChordShapes helper (which includes case-insensitivity and slash fallback)
        if (getChordShapes(cleanChord).isEmpty) {
          // Try stripping 'M' suffix if it's e.g. 'CM' instead of 'C'
          if (cleanChord.endsWith('M') && cleanChord.length > 1) {
            final testChord = cleanChord.substring(0, cleanChord.length - 1);
            if (getChordShapes(testChord).isNotEmpty) {
              continue;
            }
          }
          missing.add(chord);
        }
      }
      if (missing.isNotEmpty) {
        fail(
          'For song "$songTitle", the following chords are missing from the chord shapes database: $missing',
        );
      }
    }

    test(
      'Ultimate Guitar parses 10 songs and verifies chords & lack of paywall',
      () async {
        final dir = Directory('test/samples/songs/ultimateguitar');
        expect(dir.existsSync(), isTrue);

        final files = dir.listSync().whereType<File>().toList();
        expect(files.length, equals(10));

        for (final file in files) {
          final filename = file.uri.pathSegments.last;
          print('UltimateGuitar testing: $filename');
          final url = ugUrlMapping[filename];
          expect(url, isNotNull, reason: 'No mapped URL for $filename');

          final html = file.readAsStringSync();
          final source = UltimateGuitarSource(fetchHtmlFn: (u) async => html);

          final song = await source.getSong(url!);
          expect(song.title, isNotEmpty);
          expect(song.title.toLowerCase(), isNot(contains('unknown')));
          expect(song.artist, isNotEmpty);
          expect(song.artist.toLowerCase(), isNot(contains('unknown')));
          expect(song.lyrics, isNotEmpty);
          expect(song.lyrics, isNot(contains('Content not found')));

          // Verify no paywall indicators or Official PRO versions
          expect(song.instrument?.toLowerCase(), isNot(contains('official')));
          expect(song.lyrics.toLowerCase(), isNot(contains('pro version')));
          expect(song.lyrics.toLowerCase(), isNot(contains('paywall')));

          // Verify chords
          final chords = extractChords(song.chords ?? '');
          expect(
            chords,
            isNotEmpty,
            reason: 'No chords found in song ${song.title}',
          );
          verifySongChords('${song.artist} - ${song.title}', chords);
        }
      },
    );

    test(
      'La Cuerda parses 10 songs and verifies chords & lack of paywall',
      () async {
        final dir = Directory('test/samples/songs/lacuerda');
        expect(dir.existsSync(), isTrue);

        final files = dir.listSync().whereType<File>().toList();
        expect(files.length, equals(10));

        for (final file in files) {
          final filename = file.uri.pathSegments.last;
          print('LaCuerda testing: $filename');
          final url = laCuerdaUrlMapping[filename];
          expect(url, isNotNull, reason: 'No mapped URL for $filename');

          final html = file.readAsStringSync();
          final source = LaCuerdaSource(fetchHtmlFn: (u) async => html);

          final song = await source.getSong(url!);
          expect(song.title, isNotEmpty);
          expect(song.title.toLowerCase(), isNot(contains('unknown')));
          expect(song.artist, isNotEmpty);
          expect(song.artist.toLowerCase(), isNot(contains('unknown')));
          expect(song.lyrics, isNotEmpty);
          expect(song.lyrics, isNot(contains('Content not found')));
          expect(song.lyrics, isNot(contains('Código incorrecto')));

          // Verify chords
          final chords = extractChords(song.chords ?? '');
          expect(
            chords,
            isNotEmpty,
            reason: 'No chords found in song ${song.title}',
          );
          verifySongChords('${song.artist} - ${song.title}', chords);
        }
      },
    );

    test(
      'Cifra Club parses 10 songs and verifies chords & lack of paywall',
      () async {
        final dir = Directory('test/samples/songs/cifraclub');
        expect(dir.existsSync(), isTrue);

        final files = dir.listSync().whereType<File>().toList();
        expect(files.length, equals(10));

        for (final file in files) {
          final filename = file.uri.pathSegments.last;
          print('CifraClub testing: $filename');
          final url = cifraClubUrlMapping[filename];
          expect(url, isNotNull, reason: 'No mapped URL for $filename');

          final html = file.readAsStringSync();
          final source = CifraclubSource(fetchHtmlFn: (u) async => html);

          final song = await source.getSong(url!);
          expect(song.title, isNotEmpty);
          expect(song.title.toLowerCase(), isNot(contains('unknown')));
          expect(song.artist, isNotEmpty);
          expect(song.artist.toLowerCase(), isNot(contains('unknown')));
          expect(song.lyrics, isNotEmpty);
          expect(song.lyrics, isNot(contains('Content not found')));

          // Verify chords
          final chords = extractChords(song.chords ?? '');
          expect(
            chords,
            isNotEmpty,
            reason: 'No chords found in song ${song.title}',
          );
          verifySongChords('${song.artist} - ${song.title}', chords);
        }
      },
    );

    test(
      'Cifras parses 10 songs and verifies chords & lack of paywall',
      () async {
        final dir = Directory('test/samples/songs/cifras');
        expect(dir.existsSync(), isTrue);

        final files = dir.listSync().whereType<File>().toList();
        expect(files.length, equals(10));

        for (final file in files) {
          final filename = file.uri.pathSegments.last;
          print('Cifras testing: $filename');
          final url = cifrasUrlMapping[filename];
          expect(url, isNotNull, reason: 'No mapped URL for $filename');

          final html = file.readAsStringSync();
          final source = CifrasSource(fetchHtmlFn: (u) async => html);

          final song = await source.getSong(url!);
          expect(song.title, isNotEmpty);
          expect(song.title.toLowerCase(), isNot(contains('unknown')));
          expect(song.artist, isNotEmpty);
          expect(song.artist.toLowerCase(), isNot(contains('unknown')));
          expect(song.lyrics, isNotEmpty);
          expect(song.lyrics, isNot(contains('Content not found')));

          // Verify chords
          final chords = extractChords(song.chords ?? '');
          expect(
            chords,
            isNotEmpty,
            reason: 'No chords found in song ${song.title}',
          );
          verifySongChords('${song.artist} - ${song.title}', chords);
        }
      },
    );
  });
}
