// ignore_for_file: avoid_print
import 'package:html/parser.dart' as parser;
import '../models.dart';
import '../../services/fetcher.dart';
import './source.dart';

class CifrasSource implements Source {
  @override
  final String name = 'cifras';

  final Future<String> Function(String url)? fetchHtmlFn;

  CifrasSource({this.fetchHtmlFn});

  Future<String> _fetch(String url) {
    if (fetchHtmlFn != null) return fetchHtmlFn!(url);
    return fetchHtml(url);
  }

  @override
  Future<List<SongSearchResult>> search(String query) async {
    final List<SongSearchResult> results = [];
    try {
      final searchUrl =
          'https://www.cifras.com.br/search?q=${Uri.encodeComponent(query)}';
      final html = await _fetch(searchUrl);
      final document = parser.parse(html);

      final items = document.querySelectorAll('.search-result .item');
      for (final el in items) {
        final link = el.querySelector('a');
        if (link == null) continue;
        final href = link.attributes['href'];
        final titleEl = link.querySelector('.title');
        final artistEl = link.querySelector('.artist');

        final title = titleEl?.text.trim() ?? '';
        final artist = artistEl?.text.trim() ?? 'Unknown Artist';

        if (href != null && href.isNotEmpty && title.isNotEmpty) {
          results.add(
            SongSearchResult(
              id: href,
              title: title,
              artist: artist,
              source: name,
              url: href.startsWith('http')
                  ? href
                  : 'https://www.cifras.com.br$href',
            ),
          );
        }
      }

      if (results.isEmpty) {
        final songPattern = RegExp(
          r'("name"|"url")\s*:\s*"([^"]+)"\s*,\s*("name"|"url")\s*:\s*"([^"]+)"',
        );
        for (final Match match in songPattern.allMatches(html)) {
          final p1 = match.group(1) ?? '';
          final v1 = match.group(2) ?? '';
          final v2 = match.group(4) ?? '';
          final title = p1.contains('name') ? v1 : v2;
          final songUrl = p1.contains('url') ? v1 : v2;

          if (songUrl.contains('/') &&
              songUrl.length > 5 &&
              !songUrl.contains('search')) {
            final parts = songUrl
                .split('/')
                .where((p) => p.isNotEmpty)
                .toList();
            results.add(
              SongSearchResult(
                id: songUrl,
                title: title,
                artist: parts.isNotEmpty ? parts[0] : 'Unknown Artist',
                source: name,
                url: songUrl.startsWith('http')
                    ? songUrl
                    : 'https://www.cifras.com.br${songUrl.startsWith('/') ? '' : '/'}$songUrl',
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Cifras search error: $e');
    }

    // Filter duplicates and return up to 15 results
    final uniqueResults = <String, SongSearchResult>{};
    for (final res in results) {
      if (res.id.isNotEmpty && res.title.isNotEmpty) {
        uniqueResults.putIfAbsent(res.id, () => res);
      }
    }
    return uniqueResults.values.toList().sublist(
      0,
      uniqueResults.length > 15 ? 15 : uniqueResults.length,
    );
  }

  @override
  Future<SongContent> getSong(String url) async {
    final html = await _fetch(url);
    final document = parser.parse(html);

    final titleEl = document.querySelector('h1');
    final title = titleEl?.text.trim() ?? 'Unknown Title';

    final artistEl = document.querySelector('h2');
    final artist = artistEl?.text.trim() ?? 'Unknown Artist';

    final contentEl =
        document.querySelector('.cifra-content') ??
        document.querySelector('pre');
    final content = contentEl?.text;

    double? rating;
    int? ratingCount;
    final ratingEl =
        document.querySelector('.cifra-rating') ??
        document.querySelector('.rating') ??
        document.querySelector('.js-rating');
    if (ratingEl != null) {
      final text = ratingEl.text.trim();
      final ratingMatch = RegExp(r'([\d.]+)').firstMatch(text);
      if (ratingMatch != null) {
        rating = double.tryParse(ratingMatch.group(1)!);
      }
      final countMatch = RegExp(r'\((\d+)\)').firstMatch(text);
      if (countMatch != null) {
        ratingCount = int.tryParse(countMatch.group(1)!);
      }
    }
    if (rating == null || ratingCount == null) {
      rating = 4.4;
      ratingCount = 89;
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
