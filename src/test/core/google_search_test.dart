import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/models.dart';
import 'package:acorde/ui/screens/search_screen.dart';

void main() {
  test('Google search result parsing yields clean song metadata', () {
    // Setup mockup helper inside test or invoke state directly
    // Since _parseGoogleSearchResult is private inside SearchScreenState,
    // let's verify custom parsing patterns or create the SearchScreenState to invoke it.
    final searchScreen = const SearchScreen();
    final state = searchScreen.createState() as SearchScreenState;

    // Test Ultimate Guitar parsing
    final resultUg = state.parseGoogleSearchResult(
      'FLACA CHORDS by Andrés Calamaro @ Ultimate-Guitar.Com',
      'https://tabs.ultimate-guitar.com/tab/andres-calamaro/flaca-chords-39144',
    );
    expect(resultUg, isNotNull);
    expect(resultUg!.title, equals('FLACA'));
    expect(resultUg.artist, equals('Andrés Calamaro'));
    expect(resultUg.source, equals('ultimateguitar'));
    expect(resultUg.id, equals('andres-calamaro/flaca-chords-39144'));

    // Test Cifra Club parsing
    final resultCc = state.parseGoogleSearchResult(
      'Flaca - Andrés Calamaro - Cifra Club',
      'https://www.cifraclub.com.br/andres-calamaro/flaca/',
    );
    expect(resultCc, isNotNull);
    expect(resultCc!.title, equals('Flaca'));
    expect(resultCc.artist, equals('Andrés Calamaro'));
    expect(resultCc.source, equals('cifraclub'));
    expect(resultCc.id, equals('andres-calamaro/flaca/'));

    // Test La Cuerda parsing
    final resultLc = state.parseGoogleSearchResult(
      'Flaca, Andrés Calamaro: Acordes - LaCuerda',
      'http://acordes.lacuerda.net/andres_calamaro/flaca.shtml',
    );
    expect(resultLc, isNotNull);
    expect(resultLc!.title, equals('Flaca'));
    expect(resultLc.artist, equals('Andrés Calamaro'));
    expect(resultLc.source, equals('lacuerda'));
    expect(resultLc.id, equals('andres_calamaro/flaca.shtml'));

    // Test Cifras parsing
    final resultCif = state.parseGoogleSearchResult(
      'Flaca - Andrés Calamaro - Cifras',
      'https://www.cifras.com.br/cifra/andres-calamaro/flaca',
    );
    expect(resultCif, isNotNull);
    expect(resultCif!.title, equals('Flaca'));
    expect(resultCif.artist, equals('Andrés Calamaro'));
    expect(resultCif.source, equals('cifras'));
    expect(resultCif.id, equals('andres-calamaro/flaca'));

    // Unsupported URL returns null
    final unsupported = state.parseGoogleSearchResult(
      'Some Random Site',
      'https://example.com/song',
    );
    expect(unsupported, isNull);
  });
}
