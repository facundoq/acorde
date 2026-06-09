// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:html/parser.dart' as parser;
import '../models.dart';
import '../../services/fetcher.dart';
import './source.dart';

class UltimateGuitarSource implements Source {
  @override
  final String name = 'ultimateguitar';

  final Future<String> Function(String url)? fetchHtmlFn;

  UltimateGuitarSource({this.fetchHtmlFn});

  Future<String> _fetch(String url) {
    if (fetchHtmlFn != null) return fetchHtmlFn!(url);
    return fetchHtml(url);
  }

  @override
  Future<List<SongSearchResult>> search(String query) async {
    final List<SongSearchResult> results = [];
    try {
      final searchUrl =
          'https://www.ultimate-guitar.com/search.php?search_type=title&order=&value=${Uri.encodeComponent(query).replaceAll('%20', '+')}';
      final html = await _fetch(searchUrl);

      final document = parser.parse(html);
      final jsStore = document.querySelector('.js-store');
      final jsonStr = jsStore?.attributes['data-content'];

      if (jsonStr != null) {
        try {
          final data = jsonDecode(jsonStr);
          final searchResults = data['store']?['page']?['data']?['results'];

          if (searchResults is List) {
            for (final res in searchResults) {
              if (res == null || res is! Map) continue;
              final typeName = (res['type_name'] ?? res['type'] ?? '')
                  .toString();
              final type = typeName.toLowerCase();
              final url = (res['tab_url'] ?? '').toString();

              final isPro = res['is_pro'] == true;
              final isExcludedType =
                  isPro ||
                  type.contains('pro') ||
                  type.contains('official') ||
                  type.contains('power') ||
                  type.contains('guitar pro') ||
                  type.contains('video');

              final isPublicPattern = url.contains('ultimate-guitar.com/tab/');

              if (url.isNotEmpty && !isExcludedType && isPublicPattern) {
                results.add(
                  SongSearchResult(
                    id: url,
                    title: (res['song_name'] ?? 'Unknown').toString(),
                    artist: (res['artist_name'] ?? 'Unknown').toString(),
                    source: name,
                    url: url,
                    instrument: typeName,
                    rating: double.tryParse((res['rating'] ?? '').toString()),
                  ),
                );
              }
            }
          }
        } catch (e) {
          print('UG search JSON parse error: $e');
        }
      } else {
        // Fallback for mobile / responsive direct HTML layout
        final links = document.querySelectorAll('a[href*="/tab/"]');
        for (final link in links) {
          final href = link.attributes['href'] ?? '';
          final title = link.text.trim();
          if (href.isNotEmpty && title.isNotEmpty) {
            final uri = Uri.tryParse(href);
            if (uri == null) continue;
            final pathSegments = uri.pathSegments;
            if (pathSegments.length >= 3 && pathSegments[0] == 'tab') {
              final rawArtist = pathSegments[1].replaceAll('-', ' ');
              final artist = rawArtist.split(' ').map((word) {
                if (word.isEmpty) return '';
                return word[0].toUpperCase() + word.substring(1);
              }).join(' ');

              String instrument = 'Chords';
              final lastSegment = pathSegments[2].toLowerCase();
              if (lastSegment.contains('chords')) {
                instrument = 'Chords';
              } else if (lastSegment.contains('ukulele')) {
                instrument = 'Ukulele';
              } else if (lastSegment.contains('bass')) {
                instrument = 'Bass';
              } else if (lastSegment.contains('tab')) {
                instrument = 'Tab';
              }

              // De-duplicate: don't add the same tab twice
              if (!results.any((r) => r.url == href)) {
                results.add(
                  SongSearchResult(
                    id: href,
                    title: title,
                    artist: artist,
                    source: name,
                    url: href,
                    instrument: instrument,
                  ),
                );
              }
            }
          }
        }
      }

      // Regex fallback if results list is empty
      if (results.isEmpty) {
        final songNamePattern = RegExp(
          r'[\x22\x27]?(?:song_name|name|songName|title)[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
          caseSensitive: false,
        );
        final tabUrlPattern = RegExp(
          r'[\x22\x27]?(?:tab_url|url|tabUrl)[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
          caseSensitive: false,
        );
        final artistNamePattern = RegExp(
          r'[\x22\x27]?(?:artist_name|artist|artistName)[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
          caseSensitive: false,
        );
        final typeNamePattern = RegExp(
          r'[\x22\x27]?(?:type_name|type|typeName)[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
          caseSensitive: false,
        );

        final htmlClean = html.replaceAll(r'\"', '"');

        List<String> execRegex(RegExp regex, String str) {
          final List<String> matches = [];
          for (final Match m in regex.allMatches(str)) {
            matches.add(m.group(1) ?? '');
          }
          return matches;
        }

        final songNames = execRegex(songNamePattern, htmlClean);
        final tabUrls = execRegex(tabUrlPattern, htmlClean);
        final artistNames = execRegex(artistNamePattern, htmlClean);
        final typeNames = execRegex(typeNamePattern, htmlClean);

        final minLength = songNames.length < tabUrls.length
            ? songNames.length
            : tabUrls.length;

        for (int i = 0; i < minLength; i++) {
          final title = songNames[i];
          final url = tabUrls[i].replaceAll(r'\', '');
          final artist = i < artistNames.length ? artistNames[i] : 'Unknown';
          final typeName = i < typeNames.length ? typeNames[i] : '';

          final lowerType = typeName.toLowerCase();
          final isExcludedType =
              lowerType.contains('pro') ||
              lowerType.contains('official') ||
              lowerType.contains('power') ||
              lowerType.contains('guitar pro') ||
              lowerType.contains('video');

          final isPublicPattern = url.contains('ultimate-guitar.com/tab/');

          if (!isExcludedType && isPublicPattern) {
            results.add(
              SongSearchResult(
                id: url,
                title: title,
                artist: artist,
                source: name,
                url: url,
                instrument: typeName,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('UltimateGuitar search error: $e');
    }
    return results.sublist(0, results.length > 20 ? 20 : results.length);
  }

  @override
  Future<SongContent> getSong(String url) async {
    final html = await _fetch(url);
    if (html.contains('Just a moment...') ||
        html.contains('challenge-running')) {
      throw Exception(
        'Ultimate Guitar bot detection active. Please try again later or use the Android app.',
      );
    }

    final document = parser.parse(html);
    final jsStore = document.querySelector('.js-store');
    final jsonStr = jsStore?.attributes['data-content'];

    if (jsonStr != null) {
      try {
        final data = jsonDecode(jsonStr);
        final tabData =
            data['store']?['page']?['data']?['tab'] ??
            data['store']?['page']?['data']?['tab_view']?['tab'] ??
            {};
        final tabView = data['store']?['page']?['data']?['tab_view'] ?? {};
        final wikiTab = tabView['wiki_tab'] ?? {};
        final content =
            wikiTab['content'] ?? tabView['tab_view']?['wiki_tab']?['content'];

        if (tabData['song_name'] != null || content != null) {
          final title = (tabData['song_name'] ?? 'Unknown Title').toString();
          final artist = (tabData['artist_name'] ?? 'Unknown Artist')
              .toString();
          final lyrics = (content ?? 'Content not found').toString();

          return SongContent(
            title: title,
            artist: artist,
            lyrics: lyrics,
            chords: lyrics,
            url: url,
            source: name,
            instrument: (tabData['type_name'] ?? '').toString(),
            rating: double.tryParse((tabData['rating'] ?? '').toString()),
          );
        }
      } catch (e) {
        print('UG detail JSON parse error: $e');
      }
    }

    // Regex fallback
    final contentMatch = RegExp(
      r'[\x22\x27]?content[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
      caseSensitive: false,
    ).firstMatch(html);
    final titleMatch = RegExp(
      r'[\x22\x27]?(?:song_name|name|songName|title)[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
      caseSensitive: false,
    ).firstMatch(html);
    final artistMatch = RegExp(
      r'[\x22\x27]?(?:artist_name|artist|artistName)[\x22\x27]?\s*:\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]',
      caseSensitive: false,
    ).firstMatch(html);

    if (contentMatch != null) {
      final content = contentMatch
          .group(1)!
          .replaceAll(r'\r\n', '\n')
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\"', '"');

      return SongContent(
        title: titleMatch != null ? titleMatch.group(1)! : 'Unknown Title',
        artist: artistMatch != null ? artistMatch.group(1)! : 'Unknown Artist',
        lyrics: content,
        chords: content,
        url: url,
        source: name,
      );
    }

    print('UG parsing failed for $url. HTML length: ${html.length}');
    return SongContent(
      title: 'Unknown Title',
      artist: 'Unknown Artist',
      lyrics: 'Could not parse content',
      url: url,
      source: name,
    );
  }
}
