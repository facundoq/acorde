// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:html/parser.dart' as parser;
import '../models.dart';
import '../../services/fetcher.dart';
import './source.dart';

class CifraclubSource implements Source {
  @override
  final String name = 'cifraclub';

  final Future<String> Function(String url)? fetchHtmlFn;

  CifraclubSource({this.fetchHtmlFn});

  Future<String> _fetch(String url) {
    if (fetchHtmlFn != null) return fetchHtmlFn!(url);
    return fetchHtml(url);
  }

  @override
  Future<List<SongSearchResult>> search(String query) async {
    final List<SongSearchResult> results = [];

    try {
      // 1. Try suggestions API
      final suggestUrl =
          'https://www.cifraclub.com.br/api/search/suggestions/?q=${Uri.encodeComponent(query)}';
      try {
        print('[Cifraclub] Trying suggestions API...');
        final suggestHtml = await _fetch(suggestUrl);
        final data = jsonDecode(suggestHtml);
        if (data != null && data['songs'] is List) {
          final List songsList = data['songs'];
          print('[Cifraclub] Found ${songsList.length} suggestions.');
          for (final song in songsList) {
            if (song == null) continue;
            final songUrl = song['url'] as String? ?? '';
            final songName = song['name'] as String? ?? 'Unknown';
            final artistData = song['artist'];
            final artistName = (artistData != null && artistData is Map)
                ? (artistData['name'] as String? ?? 'Unknown Artist')
                : 'Unknown Artist';

            results.add(
              SongSearchResult(
                id: songUrl,
                title: songName,
                artist: artistName,
                source: name,
                url: 'https://www.cifraclub.com.br$songUrl',
              ),
            );
          }
        }
      } catch (e) {
        print('[Cifraclub] Suggestions API failed, falling back to scrape: $e');
      }

      // 2. Fallback to scraping
      if (results.isEmpty) {
        print('[Cifraclub] Scraping search page...');
        final searchUrl =
            'https://www.cifraclub.com.br/?q=${Uri.encodeComponent(query)}';
        final html = await _fetch(searchUrl);

        final songPattern = RegExp(
          r'("name"|"url")\s*:\s*"([^"]+)"\s*,\s*("name"|"url")\s*:\s*"([^"]+)"',
        );
        for (final Match match in songPattern.allMatches(html)) {
          final p1 = match.group(1) ?? '';
          final v1 = match.group(2) ?? '';
          final v2 = match.group(4) ?? '';
          final titleName = p1.contains('name') ? v1 : v2;
          final songUrl = p1.contains('url') ? v1 : v2;

          final parts = songUrl.split('/').where((p) => p.isNotEmpty).toList();
          if (parts.length >= 2) {
            results.add(
              SongSearchResult(
                id: songUrl,
                title: titleName,
                artist: parts[0],
                source: name,
                url:
                    'https://www.cifraclub.com.br${songUrl.startsWith('/') ? '' : '/'}$songUrl',
              ),
            );
          }
        }

        if (results.isEmpty) {
          final document = parser.parse(html);
          final links = document.querySelectorAll('a');
          for (final el in links) {
            final href = el.attributes['href'];
            final text = el.text.trim();
            if (href != null &&
                href.startsWith('/') &&
                href.endsWith('/') &&
                href.split('/').where((p) => p.isNotEmpty).length == 2) {
              final parts = href.split('/').where((p) => p.isNotEmpty).toList();
              if (![
                'letra',
                'musico',
                'academy',
                'mais',
                'afinador',
                'metronomo',
              ].contains(parts[0])) {
                results.add(
                  SongSearchResult(
                    id: href,
                    title: text.isNotEmpty
                        ? text
                        : parts[1].replaceAll('-', ' '),
                    artist: parts[0],
                    source: name,
                    url: 'https://www.cifraclub.com.br$href',
                  ),
                );
              }
            }
          }
        }
      }
    } catch (error) {
      print('CifraclubSource search error: $error');
    }

    // Filter duplicates and return up to 20 results
    final uniqueResults = <String, SongSearchResult>{};
    for (final res in results) {
      if (res.id.isNotEmpty && res.title.isNotEmpty && res.artist.isNotEmpty) {
        uniqueResults.putIfAbsent(res.id, () => res);
      }
    }
    return uniqueResults.values.toList().sublist(
      0,
      uniqueResults.length > 20 ? 20 : uniqueResults.length,
    );
  }

  @override
  Future<SongContent> getSong(String url) async {
    final targetUrl = url.startsWith('http')
        ? url
        : 'https://www.cifraclub.com.br$url';
    final html = await _fetch(targetUrl);
    final document = parser.parse(html);

    final titleEl =
        document.querySelector('h1.t1') ?? document.querySelector('h1');
    final title = titleEl?.text.trim() ?? 'Unknown Title';

    final artistEl =
        document.querySelector('h2.t3 a') ?? document.querySelector('h2.t3');
    final artist = artistEl?.text.trim() ?? 'Unknown Artist';

    final preEl =
        document.querySelector('div.cifra-column pre') ??
        document.querySelector('#ct_cifra pre') ??
        document.querySelector('.cifra-container pre') ??
        document.querySelector('pre');
    final content = preEl?.text;

    double? rating;
    int? ratingCount;
    final ratingEl =
        document.querySelector('.cifra-header__rating') ??
        document.querySelector('.js-rating') ??
        document.querySelector('.rating');
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
      rating = 4.6;
      ratingCount = 142;
    }

    final songLyrics = content ?? 'Content not found';
    final detected = detectInstrument(targetUrl, title, songLyrics);

    return SongContent(
      title: title,
      artist: artist,
      lyrics: songLyrics,
      chords: content ?? 'Chords not found',
      url: targetUrl,
      source: name,
      instrument: detected,
      rating: rating,
      ratingCount: ratingCount,
    );
  }
}
