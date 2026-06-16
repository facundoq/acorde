import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/ug_parser.dart';

void main() {
  group('UG Parser', () {
    group('isUGFormat', () {
      test('should detect UG format with [ch] tags', () {
        const content = 'Wild Horses [ch]G[/ch]';
        expect(isUGFormat(content), isTrue);
      });

      test('should detect UG format with [tab] tags', () {
        const content = '[tab]  G  Am7  [/tab]';
        expect(isUGFormat(content), isTrue);
      });

      test('should detect UG format with section headers', () {
        const content = '[Verse 1]\nChildhood living is easy to do';
        expect(isUGFormat(content), isTrue);
      });

      test('should detect UG format with chord-only lines', () {
        const content = 'C G Am F\nSome lyrics';
        expect(isUGFormat(content), isTrue);
      });

      test('should return false for plain text', () {
        const content = 'Just some regular lyrics without structure';
        expect(isUGFormat(content), isFalse);
      });

      test('should handle empty or null content', () {
        expect(isUGFormat(''), isFalse);
        expect(isUGFormat(null), isFalse);
      });
    });

    group('autoTagChords', () {
      test('should wrap chords in [ch] tags for chord-only lines', () {
        const content = 'C G Am F';
        expect(
          autoTagChords(content),
          equals('[ch]C[/ch] [ch]G[/ch] [ch]Am[/ch] [ch]F[/ch]'),
        );
      });

      test('should wrap chords in [ch] tags for chords above lyrics', () {
        const content = '  C        G\nLyrics here';
        final tagged = autoTagChords(content);
        expect(tagged, contains('[ch]C[/ch]'));
        expect(tagged, contains('[ch]G[/ch]'));
      });

      test('should not wrap headers', () {
        const content = '[Intro]';
        expect(autoTagChords(content), equals('[Intro]'));
      });

      test('should handle complex chords like Bb/D', () {
        const content = 'Bb/D C7sus4';
        expect(autoTagChords(content), equals('[ch]Bb/D[/ch] [ch]C7sus4[/ch]'));
      });
    });

    group('parseUGTabs', () {
      test('should parse [ch] tags correctly', () {
        const content = 'Some [ch]G[/ch] and [ch]C[/ch] chords';
        final parts = parseUGTabs(content);

        expect(parts.length, equals(5));
        expect(parts[0].type, equals(UGPartType.text));
        expect(parts[0].content, equals('Some '));
        expect(parts[1].type, equals(UGPartType.chord));
        expect(parts[1].content, equals('G'));
        expect(parts[2].type, equals(UGPartType.text));
        expect(parts[2].content, equals(' and '));
        expect(parts[3].type, equals(UGPartType.chord));
        expect(parts[3].content, equals('C'));
        expect(parts[4].type, equals(UGPartType.text));
        expect(parts[4].content, equals(' chords'));
      });

      test('should parse [tab] tags correctly', () {
        const content = 'Intro:\n[tab]  [ch]G[/ch]  [ch]Am7[/ch]  [/tab]';
        final parts = parseUGTabs(content);

        final hasTab = parts.any(
          (p) =>
              p.type == UGPartType.tab &&
              p.content == '  [ch]G[/ch]  [ch]Am7[/ch]  ',
        );
        expect(hasTab, isTrue);
      });

      test('should parse section headers correctly', () {
        const content = '[Intro]\n[Verse 1]\nLyrics';
        final parts = parseUGTabs(content);

        expect(parts.length, equals(4));
        expect(parts[0].type, equals(UGPartType.header));
        expect(parts[0].content, equals('[Intro]'));
        expect(parts[1].type, equals(UGPartType.text));
        expect(parts[1].content, equals('\n'));
        expect(parts[2].type, equals(UGPartType.header));
        expect(parts[2].content, equals('[Verse 1]'));
        expect(parts[3].type, equals(UGPartType.text));
        expect(parts[3].content, equals('\nLyrics'));
      });

      test('should parse complex UG content', () {
        const content =
            '[Intro]  | [ch]G[/ch] | [ch]Am7[/ch] |\n\n[Verse]\n[tab]  [ch]Bm[/ch]          [ch]G[/ch]      [ch]Bm[/ch]           [ch]G[/ch]\n    Childhood living   is easy to do[/tab]';

        final parts = parseUGTabs(content);

        final hasIntro = parts.any(
          (p) => p.type == UGPartType.header && p.content == '[Intro]',
        );
        final hasG = parts.any(
          (p) => p.type == UGPartType.chord && p.content == 'G',
        );
        final hasVerse = parts.any(
          (p) => p.type == UGPartType.header && p.content == '[Verse]',
        );
        final hasTab = parts.any(
          (p) =>
              p.type == UGPartType.tab &&
              p.content ==
                  '  [ch]Bm[/ch]          [ch]G[/ch]      [ch]Bm[/ch]           [ch]G[/ch]\n    Childhood living   is easy to do',
        );

        expect(hasIntro, isTrue);
        expect(hasG, isTrue);
        expect(hasVerse, isTrue);
        expect(hasTab, isTrue);
      });
    });

    group('parseUGTabs tablature blocks', () {
      test('should parse guitar tablature blocks as UGPartType.tablature', () {
        const content =
            'Intro:\n'
            '|---7------7--7----------------3-------------------------------------|\n'
            'B|---6------6--6-----3-------2--2-------2-----2-2-------6--------6----|\n'
            'G|---7------7--7-----2-----3------3-----3-----3-3-----0--------0------| \n'
            'D|-----------------3---3--------------2---2-2---2---7-----7--5-----5--|\n'
            'A|-5----5-5----5------------------------------------------------------|\n'
            'E|--------------------------------------------------------------------|';

        final parts = parseUGTabs(content);
        final tabParts = parts
            .where((p) => p.type == UGPartType.tablature)
            .toList();
        expect(tabParts.length, equals(1));
        expect(tabParts[0].content, contains('|---7------7--7'));
        expect(tabParts[0].content, contains('E|-------'));
      });
    });

    group('parseGenericTabs', () {
      test(
        'should parse generic tablature blocks without autotagging chords',
        () {
          const content =
              'Intro:\n'
              'C G Am F\n'
              '|---7------7--7----------------3---|\n'
              'B|---6------6--6-----3-------2--2---|\n'
              'G|---7------7--7-----2-----3------3-|\n'
              'D|-----------------3---3------------|\n'
              'A|-5----5-5----5--------------------|\n'
              'E|----------------------------------|\n'
              'Some regular lyrics';

          final parts = parseGenericTabs(content);
          final tabParts = parts
              .where((p) => p.type == UGPartType.tablature)
              .toList();
          final textParts = parts
              .where((p) => p.type == UGPartType.text)
              .toList();

          expect(tabParts.length, equals(1));
          expect(tabParts[0].content, contains('|---7------7--7'));

          // It should NOT contain [ch] tags in text parts because it does not autotag chords
          expect(textParts.any((p) => p.content.contains('[ch]')), isFalse);
          expect(
            textParts.any((p) => p.content.contains('Some regular lyrics')),
            isTrue,
          );
        },
      );
    });
  });
}
