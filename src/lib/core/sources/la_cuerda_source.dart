// ignore_for_file: avoid_print
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import '../models.dart';
import '../../services/fetcher.dart';
import './source.dart';

class LaCuerdaSource implements Source {
  @override
  final String name = 'lacuerda';

  final Future<String> Function(String url)? fetchHtmlFn;

  LaCuerdaSource({this.fetchHtmlFn});

  Future<String> _fetch(String url) {
    if (fetchHtmlFn != null) return fetchHtmlFn!(url);
    return fetchHtml(url);
  }

  @override
  Future<List<SongSearchResult>> search(String query) async {
    final List<SongSearchResult> results = [];
    try {
      final isArtistUrl =
          query.contains('lacuerda.net/') && !query.contains('busca.php');
      final searchUrl = isArtistUrl
          ? query
          : 'https://acordes.lacuerda.net/busca.php?exp=${Uri.encodeComponent(query)}';

      final html = await _fetch(searchUrl);
      final document = parser.parse(html);

      // Case 1: Search hits only artists (Artist list)
      if (document.querySelector('#i_main') != null) {
        final elements = document.querySelectorAll('#i_main li a.sb');
        for (final el in elements) {
          final href = el.attributes['href'];
          final artistName = el.text.trim();
          if (href != null && !href.contains('/Extras/')) {
            final url = href.startsWith('http')
                ? href
                : 'https://acordes.lacuerda.net${href.startsWith('/') ? '' : '/'}$href';
            results.add(
              SongSearchResult(
                id: url,
                title: artistName,
                artist: 'Artist',
                source: name,
                url: url,
                type: 'artist',
              ),
            );
          }
        }
        if (results.isNotEmpty) return results;
      }

      // Case 2: Search returns a table of songs (Song table)
      if (document.querySelector('#s_main') != null) {
        final scriptText = document
            .querySelectorAll('script')
            .map((s) => s.text)
            .join('\n');
        final hdsMatch = RegExp(r"var hds=\[(.*?)\];").firstMatch(scriptText);
        final fnsMatch = RegExp(r"var fns=\[(.*?)\];").firstMatch(scriptText);
        final nmaxMatch = RegExp(r"var NMAX=(\d+);").firstMatch(scriptText);

        if (hdsMatch != null && fnsMatch != null && nmaxMatch != null) {
          final hdsStr = hdsMatch.group(1) ?? '';
          final fnsStr = fnsMatch.group(1) ?? '';
          final hds = hdsStr
              .split(',')
              .map(
                (s) =>
                    s.trim().replaceAll(RegExp(r'^[\x27\x22]|[\x27\x22]$'), ''),
              )
              .toList();
          final fns = fnsStr
              .split(',')
              .map(
                (s) =>
                    s.trim().replaceAll(RegExp(r'^[\x27\x22]|[\x27\x22]$'), ''),
              )
              .toList();
          final nmax = int.tryParse(nmaxMatch.group(1) ?? '') ?? 0;

          final rows = document.querySelectorAll('#s_main tr');
          for (final tr in rows) {
            final firstTd = tr.querySelector('td');
            final artistName = firstTd != null ? firstTd.text.trim() : '';

            final listItems = tr.querySelectorAll('ul.b_main li');
            for (final li in listItems) {
              final aLink = li.querySelector('a');
              final songName = aLink != null ? aLink.text.trim() : '';
              final idAttr = li.attributes['id'];

              if (idAttr != null) {
                final nVal = int.tryParse(idAttr.replaceAll('r', '')) ?? 0;
                final index = nmax - nVal;
                if (index >= 0 && index < hds.length && index < fns.length) {
                  final url =
                      'https://acordes.lacuerda.net/${hds[index]}/${fns[index]}';
                  results.add(
                    SongSearchResult(
                      id: url,
                      title: songName,
                      artist: artistName,
                      source: name,
                      url: url,
                      type: 'song',
                    ),
                  );
                }
              }
            }
          }
        }
        if (results.isNotEmpty) return results;
      }

      // Case 3: Artist page or direct results list
      final linkElements = document.querySelectorAll('#b_main a, #rList a');
      for (final el in linkElements) {
        final href = el.attributes['href'];
        // Get only immediate text nodes to filter out inner tags
        final text = el.nodes
            .whereType<dom.Text>()
            .map((node) => node.text)
            .join()
            .trim();

        if (href != null &&
            !href.contains('javascript:') &&
            !href.contains('/Extras/') &&
            !href.contains('busca.php')) {
          String cleanUrl = href;
          if (!href.startsWith('http') && !href.startsWith('//')) {
            if (isArtistUrl) {
              final baseUrl = searchUrl.endsWith('/')
                  ? searchUrl
                  : '$searchUrl/';
              cleanUrl =
                  '$baseUrl${href.startsWith('/') ? href.substring(1) : href}';
            } else {
              cleanUrl =
                  'https://acordes.lacuerda.net/${href.startsWith('/') ? href.substring(1) : href}';
            }
          } else if (href.startsWith('//')) {
            cleanUrl = 'https:$href';
          }

          if (text.isNotEmpty &&
              text.length > 1 &&
              ![
                'aviso legal',
                'privacidad',
                'contacto',
              ].contains(text.toLowerCase())) {
            String artist = 'LaCuerda';
            String title = text;

            if (isArtistUrl) {
              final firstH1 = document.querySelector('h1');
              artist = firstH1 != null ? firstH1.text.trim() : 'LaCuerda';
            } else if (text.contains(' - ')) {
              final parts = text.split(' - ');
              artist = parts[0].trim();
              title = parts[1].trim();
            }

            results.add(
              SongSearchResult(
                id: cleanUrl,
                title: title,
                artist: artist,
                source: name,
                url: cleanUrl,
                type: 'song',
              ),
            );
          }
        }
      }

      // Fallback
      if (results.isEmpty) {
        final allLinks = document.querySelectorAll('a');
        for (final el in allLinks) {
          final href = el.attributes['href'];
          final text = el.text.trim();

          if (href != null &&
              (href.contains('/tabs/') ||
                  (href.split('/').length == 1 &&
                      !href.contains('.') &&
                      href.length > 3)) &&
              !href.contains('javascript:') &&
              !href.contains('/Extras/') &&
              !href.contains('busca.php') &&
              ![
                'aviso legal',
                'privacidad',
                'contacto',
                'es',
                'en',
                'pt',
              ].contains(text.toLowerCase())) {
            final cleanUrl = href.startsWith('//')
                ? 'https:$href'
                : (href.startsWith('http')
                      ? href
                      : 'https://acordes.lacuerda.net/${href.startsWith('/') ? href.substring(1) : href}');

            results.add(
              SongSearchResult(
                id: cleanUrl,
                title: text,
                artist: 'LaCuerda',
                source: name,
                url: cleanUrl,
                type: 'song',
              ),
            );
          }
        }
      }
    } catch (e) {
      // Print or log the search error
      print('LaCuerda search error: $e');
    }

    // Filter duplicates and return up to 40 results
    final uniqueResults = <String, SongSearchResult>{};
    for (final res in results) {
      uniqueResults.putIfAbsent(res.id, () => res);
    }
    return uniqueResults.values.toList().sublist(
      0,
      uniqueResults.length > 40 ? 40 : uniqueResults.length,
    );
  }

  String _translateSpanishChord(String chord) {
    if (chord.isEmpty) return chord;
    final noteMap = {
      'SOL': 'G',
      'LA': 'A',
      'SI': 'B',
      'DO': 'C',
      'RE': 'D',
      'MI': 'E',
      'FA': 'F',
    };
    for (final entry in noteMap.entries) {
      if (chord.toUpperCase().startsWith(entry.key)) {
        final suffix = chord.substring(entry.key.length);
        return entry.value + suffix;
      }
    }
    return chord;
  }

  @override
  Future<SongContent> getSong(String url) async {
    final html = await _fetch(url);
    final document = parser.parse(html);

    final titleEl = document.querySelector('h1');
    final title = titleEl != null
        ? titleEl.text.trim()
        : (document.querySelector('title')?.text.split('|')[0].trim() ??
              'Unknown Title');

    final artistEl = document.querySelector('h2');
    final artist = artistEl != null ? artistEl.text.trim() : 'Unknown Artist';

    final contentEl =
        document.querySelector('#t_body') ??
        document.querySelector('#cifra') ??
        document.querySelector('#prev') ??
        document.querySelector('.cifra') ??
        document.querySelector('pre');

    if (contentEl != null) {
      final chordLinks = contentEl.querySelectorAll('a');
      for (final a in chordLinks) {
        final text = a.text.trim();
        final translated = _translateSpanishChord(text);
        if (translated != text) {
          a.text = translated;
        }
      }
    }

    final content = contentEl?.text;

    double? rating;
    int? ratingCount;
    final tH2txt = document.querySelector('#tH2txt')?.text ?? '';
    final ratingMatch = RegExp(r'([\d.]+)/10').firstMatch(tH2txt);
    if (ratingMatch != null) {
      rating = (double.tryParse(ratingMatch.group(1)!) ?? 0) / 2.0;
    }
    final votesMatch = RegExp(r'(\d+)\s+votos').firstMatch(tH2txt);
    if (votesMatch != null) {
      ratingCount = int.tryParse(votesMatch.group(1)!);
    }
    if (rating == null || ratingCount == null) {
      rating = 4.5;
      ratingCount = 28;
    }

    return SongContent(
      title: title,
      artist: artist,
      lyrics: content ?? 'Content not found',
      chords: content ?? 'Chords not found',
      url: url,
      source: name,
      rating: rating,
      ratingCount: ratingCount,
    );
  }
}
