import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/sources/ultimate_guitar_source.dart';
import 'package:acorde/core/ug_parser.dart';

void main() {
  group('Radiohead - Reckoner Parsing Tests', () {
    test('should parse mobile version with separated chords', () async {
      final mobileHtml = File(
        'test/samples/reckoner_mobile.html',
      ).readAsStringSync();
      final mobileSource = UltimateGuitarSource(
        fetchHtmlFn: (url) async => mobileHtml,
      );
      final song = await mobileSource.getSong(
        'https://tabs.ultimate-guitar.com/tab/radiohead/reckoner-chords-588700',
      );

      expect(song.title, equals('Reckoner'));
      expect(song.artist, equals('Radiohead'));

      final parts = parseUGTabs(song.lyrics);

      // Find the tab part that contains "Reckoner" lyrics
      final tabParts = parts.where((p) => p.type == UGPartType.tab).toList();
      expect(tabParts, isNotEmpty);

      // Let's verify the first tab part with lyrics: "Reckoner"
      // In the parsed lines, it should align Em above "Reckoner", and separate D, C, Em, C
      final reckonerTab = tabParts.firstWhere(
        (p) => p.content.contains('Reckoner'),
      );
      final alignedLines = parseAlignedSegments(reckonerTab.content);

      expect(alignedLines, isNotEmpty);
      final firstLine = alignedLines[0];
      expect(firstLine.type, equals(AlignedLineType.paired));

      // Extract all chords in this line
      final chords = firstLine.segments
          .where((s) => s.chord != null)
          .map((s) => s.chord)
          .toList();
      expect(chords, equals(['Em', 'D', 'C', 'Em', 'C']));
    });

    test('should parse desktop version with separated chords', () async {
      final desktopHtml = File(
        'test/samples/reckoner_desktop.html',
      ).readAsStringSync();
      final desktopSource = UltimateGuitarSource(
        fetchHtmlFn: (url) async => desktopHtml,
      );
      final song = await desktopSource.getSong(
        'https://tabs.ultimate-guitar.com/tab/radiohead/reckoner-chords-588700',
      );

      expect(song.title, equals('Reckoner'));
      expect(song.artist, equals('Radiohead'));

      final parts = parseUGTabs(song.lyrics);

      // Find the tab part that contains "Reckoner" lyrics
      final tabParts = parts.where((p) => p.type == UGPartType.tab).toList();
      expect(tabParts, isNotEmpty);

      final reckonerTab = tabParts.firstWhere(
        (p) => p.content.contains('Reckoner'),
      );
      final alignedLines = parseAlignedSegments(reckonerTab.content);

      expect(alignedLines, isNotEmpty);
      final firstLine = alignedLines[0];
      expect(firstLine.type, equals(AlignedLineType.paired));

      // Extract all chords in this line
      final chords = firstLine.segments
          .where((s) => s.chord != null)
          .map((s) => s.chord)
          .toList();
      expect(chords, equals(['Em', 'D', 'C', 'Em', 'C']));
    });
  });
}
