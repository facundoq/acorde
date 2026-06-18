@Timeout(Duration(hours: 12))
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/la_cuerda_source.dart';
import 'package:acorde/core/models.dart';
import 'package:html/parser.dart' as parser;

const String defaultSongsPath =
    '/home/facundoq/dev/acorde/assets/default_songs.json';
const String statusCsvPath =
    '/home/facundoq/dev/acorde/src/assets/lacuerda_scrape_status.csv';

final List<String> targetArtists = [
  'fito paez',
  'luis alberto spinetta', // Spinetta
  'charly garcia',
  'la maquina de hacer pajaros',
  'seru giran',
  'los rodriguez',
  'los piojos',
  'catupecu machu',
  'mercedes sosa',
  'astor piazzolla', // Piazolla
  'canticuenticos',
  'pequeño pez',
  'los raviolis',
  'soda stereo', // Soda estereo
  'patricio rey y sus redonditos de ricota',
  'sumo',
  'almendra',
  'pescado rabioso',
  'virus',
  'divididos',
  'rata blanca',
  'la bersuit',
  'los pericos',
  'ataque 77',
  'sui generis',
  'invisible',
  'mi amigo invencible',
  'manal',
  'los gatos',
];

Future<String> fetchWithHeadlessChrome(String url) async {
  print('Fetching via Chrome headless: $url');
  final process = await Process.start('google-chrome-stable', [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-blink-features=AutomationControlled',
    '--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    '--virtual-time-budget=5000',
    '--dump-dom',
    url,
  ]);

  final StringBuffer stdoutBuffer = StringBuffer();
  final StringBuffer stderrBuffer = StringBuffer();

  final stdoutSub = process.stdout.transform(utf8.decoder).listen((data) {
    stdoutBuffer.write(data);
  });
  final stderrSub = process.stderr.transform(utf8.decoder).listen((data) {
    stderrBuffer.write(data);
  });

  try {
    final exitCode = await process.exitCode.timeout(
      const Duration(seconds: 20),
    );
    await stdoutSub.cancel();
    await stderrSub.cancel();

    if (exitCode == 0) {
      return stdoutBuffer.toString();
    } else {
      throw Exception(
        'Chrome headless exited with code $exitCode: ${stderrBuffer.toString()}',
      );
    }
  } catch (e) {
    await stdoutSub.cancel();
    await stderrSub.cancel();
    process.kill();
    print('Chrome headless failed or timed out for $url: $e');
    throw Exception('Chrome headless timed out: $e');
  }
}

void main() {
  test('LaCuerda Scraper', () async {
    final random = Random();
    final List<Map<String, String>> csvRows = [];

    // Create/load status CSV file if it exists
    if (FileSystemEntity.typeSync(statusCsvPath) !=
        FileSystemEntityType.notFound) {
      final csvLines = File(statusCsvPath).readAsLinesSync();
      if (csvLines.length > 1) {
        for (var i = 1; i < csvLines.length; i++) {
          final parts = csvLines[i].split(',');
          if (parts.length >= 3) {
            csvRows.add({
              'title': parts[0].trim(),
              'artist': parts[1].trim(),
              'status': parts[2].trim(),
            });
          }
        }
      }
    }

    // Load existing songs
    List<dynamic> existingSongs = [];
    if (FileSystemEntity.typeSync(defaultSongsPath) !=
        FileSystemEntityType.notFound) {
      try {
        final content = File(defaultSongsPath).readAsStringSync();
        existingSongs = jsonDecode(content) as List<dynamic>;
        print('Loaded ${existingSongs.length} existing songs.');
      } catch (e) {
        print('Error reading default songs database: $e');
      }
    }

    final Set<String> existingUrls = existingSongs
        .map((s) {
          return (s['url'] as String? ?? '').trim();
        })
        .where((url) => url.isNotEmpty)
        .toSet();

    final Map<String, String> htmlCache = {};
    Future<String> fetchWithCache(String url) async {
      if (htmlCache.containsKey(url)) {
        return htmlCache[url]!;
      }
      final html = await fetchWithHeadlessChrome(url);
      htmlCache[url] = html;
      return html;
    }

    final source = LaCuerdaSource(fetchHtmlFn: fetchWithCache);

    for (final artistQuery in targetArtists) {
      print('\n=========================================');
      print('Searching artist: $artistQuery');
      print('=========================================');

      try {
        // 1. Search LaCuerda for the artist
        final searchResults = await source.search(artistQuery);

        List<SongSearchResult> songsList = [];

        // Find if there is an artist result
        String? artistUrl;
        for (final res in searchResults) {
          if (res.type == 'artist') {
            artistUrl = res.url;
            break;
          }
        }

        if (artistUrl != null) {
          print('Found artist URL: $artistUrl');
          await Future.delayed(
            Duration(milliseconds: 2000 + random.nextInt(3000)),
          );
          songsList = await source.search(artistUrl);
        } else {
          // If no specific artist page, but we got direct songs (e.g. redirected to artist page), use them!
          songsList = searchResults.where((r) => r.type == 'song').toList();
          print(
            'No specific artist URL found, using ${songsList.length} direct song search results.',
          );
        }

        final searchUrl =
            'https://acordes.lacuerda.net/busca.php?exp=${Uri.encodeComponent(artistQuery)}';
        final searchHtml = htmlCache[searchUrl] ?? htmlCache[artistUrl] ?? '';
        String? artistDir;
        if (searchHtml.isNotEmpty) {
          final videoMatch = RegExp(
            r'videos\.lacuerda\.net/([^/]+)/',
          ).firstMatch(searchHtml);
          if (videoMatch != null) {
            artistDir = videoMatch.group(1);
            print('Extracted artistDir: $artistDir');
          }
        }

        if (songsList.isEmpty) {
          print('No songs found for $artistQuery');
          csvRows.add({
            'title': 'Artist Songs List',
            'artist': artistQuery,
            'status': 'Not Found/Empty',
          });
          _saveCsv(csvRows);
          continue;
        }

        // 3. Download and parse each song
        for (var i = 0; i < songsList.length; i++) {
          final s = songsList[i];
          final cleanTitle = s.title.trim();
          final cleanArtist = s.artist.trim();

          var songUrl = s.url;
          if (artistDir != null && !songUrl.contains('/$artistDir/')) {
            final songName = songUrl.split('/').last;
            songUrl = 'https://acordes.lacuerda.net/$artistDir/$songName';
          }

          print(
            '\n[${i + 1}/${songsList.length}] Processing song: $cleanArtist - $cleanTitle (URL: $songUrl)',
          );

          if (existingUrls.contains(songUrl)) {
            print(
              'Song already exists in default_songs.json (matched by URL), skipping.',
            );
            // Update CSV status if not present
            if (!csvRows.any(
              (row) =>
                  row['title'] == cleanTitle && row['artist'] == cleanArtist,
            )) {
              csvRows.add({
                'title': cleanTitle,
                'artist': cleanArtist,
                'status': 'Already Existed',
              });
              _saveCsv(csvRows);
            }
            continue;
          }

          // Delay to prevent rate limiting
          final sleepMs = 2000 + random.nextInt(3000);
          print('Sleeping for ${sleepMs / 1000.0}s...');
          await Future.delayed(Duration(milliseconds: sleepMs));

          try {
            // Download page and parse (utilizes cache)
            final songContent = await source.getSong(songUrl);
            final htmlContent = htmlCache[songUrl] ?? '';

            var title = songContent.title;
            var artist = songContent.artist;

            if (htmlContent.isNotEmpty) {
              final doc = parser.parse(htmlContent);
              final rHeadH1 = doc.querySelector('#r_head h1');
              if (rHeadH1 != null) {
                final aLink = rHeadH1.querySelector('a');
                if (aLink != null) {
                  artist = aLink.text.trim();
                  title = rHeadH1.text.replaceAll(artist, '').trim();
                }
              }
            }

            // Cleanup if it failed or matched site headers
            if (artist.startsWith('Letras, Acordes y Tabs') ||
                artist == 'Unknown Artist' ||
                artist.isEmpty) {
              artist = cleanArtist;
            }
            if (title == 'Unknown Title' || title.isEmpty) {
              title = cleanTitle;
            }
            if (artist == 'LaCuerda') {
              artist = artistQuery
                  .split(' ')
                  .map(
                    (w) =>
                        w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '',
                  )
                  .join(' ');
            }

            final songData = {
              'source_id': s.url.split('/').last.replaceAll('.shtml', ''),
              'title': title,
              'artist': artist,
              'lyrics': songContent.lyrics,
              'chords': songContent.chords ?? songContent.lyrics,
              'source': 'lacuerda',
              'url': s.url,
              'instrument': 'Chords',
              'rating': songContent.rating ?? 4.5,
              'rating_count': songContent.ratingCount ?? 20,
            };

            // Save incrementally to default_songs.json
            existingSongs.add(songData);
            File(defaultSongsPath).writeAsStringSync(jsonEncode(existingSongs));
            existingUrls.add(songUrl);

            print('Successfully saved: $artist - $title');

            // Log status in CSV
            _updateOrAddCsv(csvRows, cleanTitle, cleanArtist, 'Downloaded');
          } catch (e) {
            print('Error downloading song ${s.url}: $e');
            _updateOrAddCsv(csvRows, cleanTitle, cleanArtist, 'Error: $e');
          }
        }
      } catch (e) {
        print('Error processing artist $artistQuery: $e');
        csvRows.add({
          'title': 'Artist Process',
          'artist': artistQuery,
          'status': 'Error: $e',
        });
        _saveCsv(csvRows);
      }
    }

    print('\nScrape process finished successfully!');
  });
}

void _saveCsv(List<Map<String, String>> rows) {
  final buffer = StringBuffer();
  buffer.writeln('Song Title,Artist,Status');
  for (final row in rows) {
    // Escape commas and quotes for CSV safety
    final title = _escapeCsv(row['title'] ?? '');
    final artist = _escapeCsv(row['artist'] ?? '');
    final status = _escapeCsv(row['status'] ?? '');
    buffer.writeln('$title,$artist,$status');
  }
  File(statusCsvPath).writeAsStringSync(buffer.toString());
}

void _updateOrAddCsv(
  List<Map<String, String>> rows,
  String title,
  String artist,
  String status,
) {
  var found = false;
  for (final row in rows) {
    if (row['title'] == title && row['artist'] == artist) {
      row['status'] = status;
      found = true;
      break;
    }
  }
  if (!found) {
    rows.add({'title': title, 'artist': artist, 'status': status});
  }
  _saveCsv(rows);
}

String _escapeCsv(String field) {
  if (field.contains(',') || field.contains('"') || field.contains('\n')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}
