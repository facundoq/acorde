enum UGPartType { text, chord, header, tab, tablature }

class UGPart {
  final UGPartType type;
  final String content;

  UGPart({required this.type, required this.content});
}

class AlignedSegment {
  final String? chord;
  final String text;

  AlignedSegment({this.chord, required this.text});
}

enum AlignedLineType { paired, single }

class AlignedLine {
  final AlignedLineType type;
  final List<AlignedSegment> segments;

  AlignedLine({required this.type, required this.segments});
}

bool isUGFormat(String? content) {
  if (content == null || content.isEmpty) return false;

  // Check for exact tags or common header patterns
  final hasTags = content.contains('[ch]') || content.contains('[tab]');
  if (hasTags) return true;

  final headerPattern = RegExp(
    r'\[(Intro|Verse|Chorus|Bridge|Outro|Solo|Instrumental|Interlude|Pre-Chorus|Riff|Hook)',
    caseSensitive: false,
  );
  if (headerPattern.hasMatch(content)) return true;

  // If it has lines that look like chords but no tags
  final lines = content.split('\n');
  for (final line in lines) {
    if (isChordOnlyLine(line)) return true;
  }

  return false;
}

// Shared chord pattern: A-G, optional # or b, optional m, maj, 7, sus, etc.
final RegExp _chordSymbolRegex = RegExp(
  r'^[A-G][#b]?(?:m|maj|min|aug|dim|sus|add|[0-9]|M)*(?:\/[A-G][#b]?(?:m|maj|min|aug|dim|sus|add|[0-9]|M)*)?$',
  caseSensitive: false,
);

bool isChordOnlyLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return false;

  // Remove common separators and brackets that might be in a chord line
  final lineWithoutSeparators = trimmed.replaceAll(
    RegExp(r'[|()\[\]\-\u2013\u2014]'),
    ' ',
  );
  final words = lineWithoutSeparators.trim().split(RegExp(r'\s+'));
  if (words.isEmpty || (words.length == 1 && words[0].isEmpty)) return false;

  int chordCount = 0;
  for (final word in words) {
    if (word.isEmpty) continue;

    if (_chordSymbolRegex.hasMatch(word)) {
      chordCount++;
    } else {
      // If any word is clearly not a chord and not a simple character, it's probably not a chord-only line
      // Allow for some common short strings in chord lines like "x2", "NC", etc.
      if (word.length > 2 &&
          word.toUpperCase() != 'N.C.' &&
          word.toUpperCase() != 'NC') {
        return false;
      }
    }
  }

  return chordCount > 0;
}

List<String> _splitWithSeparators(String line, RegExp pattern) {
  final List<String> parts = [];
  int lastIndex = 0;
  for (final Match match in pattern.allMatches(line)) {
    if (match.start > lastIndex) {
      parts.add(line.substring(lastIndex, match.start));
    }
    parts.add(match.group(0)!);
    lastIndex = match.end;
  }
  if (lastIndex < line.length) {
    parts.add(line.substring(lastIndex));
  }
  return parts;
}

String autoTagChords(String content) {
  if (content.contains('[ch]')) return content; // Already tagged

  final lines = content.split('\n');
  final separatorRegExp = RegExp(r'[^a-zA-Z0-9/#]+');

  final processedLines = lines.map((line) {
    // If it's a header or already contains tags, leave it
    final trimmed = line.trim();
    if (trimmed.startsWith('[') || line.contains('[tab]')) return line;

    // Check if it's a tab line (contains |-)
    if (line.contains('|-')) return line;

    // We split the line by everything that is NOT a word character or / #
    // to isolate potential chord symbols but keep the spacing/punctuation
    final segments = _splitWithSeparators(line, separatorRegExp);

    int chordMatchesCount = 0;
    int wordCount = 0;

    final processedSegments = segments.map((seg) {
      // If it's a separator, return it as is
      if (seg.isEmpty || separatorRegExp.hasMatch(seg)) return seg;

      wordCount++;
      if (_chordSymbolRegex.hasMatch(seg)) {
        chordMatchesCount++;
        return '[ch]$seg[/ch]';
      }
      return seg;
    }).toList();

    if (chordMatchesCount > 0 &&
        (isChordOnlyLine(line) ||
            (wordCount > 0 && chordMatchesCount / wordCount >= 0.5))) {
      return processedSegments.join('');
    }

    return line;
  });

  return processedLines.join('\n');
}

List<AlignedLine> parseAlignedSegments(String content) {
  // Ensure chords are tagged before alignment
  final taggedContent = autoTagChords(content);
  final lines = taggedContent.split('\n');
  final List<AlignedLine> result = [];

  for (int i = 0; i < lines.length; i++) {
    final currentLine = lines[i];
    final nextLine = (i + 1 < lines.length) ? lines[i + 1] : null;

    // Check if current line contains chords and next line is a text line (not headers/tags)
    final hasChords = currentLine.contains('[ch]');
    final nextIsLyrics =
        nextLine != null &&
        !nextLine.contains('[ch]') &&
        !nextLine.contains('[') &&
        nextLine.trim().isNotEmpty;

    if (hasChords && nextIsLyrics) {
      // It's a pair!
      final List<AlignedSegment> segments = [];

      final List<_ChordMatch> chords = [];
      final chordRegex = RegExp(r'\[ch\](.*?)\[\/ch\]');

      int lastIndex = 0;
      int strippedPos = 0;
      final strippedChordsLineBuffer = StringBuffer();

      for (final Match match in chordRegex.allMatches(currentLine)) {
        final prefix = currentLine.substring(lastIndex, match.start);
        strippedChordsLineBuffer.write(prefix);
        strippedPos += prefix.length;
        chords.add(_ChordMatch(match.group(1)!, strippedPos));

        strippedChordsLineBuffer.write(match.group(1)!);
        strippedPos += match.group(1)!.length;
        lastIndex = match.end;
      }
      final suffix = currentLine.substring(lastIndex);
      strippedChordsLineBuffer.write(suffix);
      strippedPos += suffix.length;
      final strippedChordsLineLength = strippedPos;

      if (chords.isNotEmpty) {
        final wordRegex = RegExp(r'\S+\s*|\s+');
        final matches = wordRegex.allMatches(nextLine).toList();

        for (int j = 0; j < matches.length; j++) {
          final m = matches[j];
          int start = m.start;
          int end = m.end;

          // Extend first and last segments to catch leading/trailing chords
          if (j == 0) {
            start = 0;
          }
          if (j == matches.length - 1) {
            end = strippedChordsLineLength > nextLine.length
                ? strippedChordsLineLength
                : nextLine.length;
          }

          final segmentChords = chords
              .where((c) => c.pos >= start && c.pos < end)
              .toList();

          final textStart = m.start < nextLine.length
              ? m.start
              : nextLine.length;
          final textEnd = m.end < nextLine.length ? m.end : nextLine.length;
          final wordText = nextLine.substring(textStart, textEnd);

          if (segmentChords.isEmpty) {
            segments.add(AlignedSegment(chord: null, text: wordText));
          } else if (segmentChords.length == 1) {
            segments.add(
              AlignedSegment(chord: segmentChords[0].name, text: wordText),
            );
          } else {
            // First chord is aligned with the text of the word
            final firstChord = segmentChords[0];
            segments.add(
              AlignedSegment(chord: firstChord.name, text: wordText),
            );

            int lastPos = firstChord.pos + firstChord.name.length;
            for (int k = 1; k < segmentChords.length; k++) {
              final c = segmentChords[k];
              final spacesCount = c.pos - lastPos;
              if (spacesCount > 0) {
                segments.add(
                  AlignedSegment(chord: null, text: ' ' * spacesCount),
                );
              }
              segments.add(AlignedSegment(chord: c.name, text: ''));
              lastPos = c.pos + c.name.length;
            }
          }
        }

        result.add(
          AlignedLine(type: AlignedLineType.paired, segments: segments),
        );
        i++; // Skip paired line
        continue;
      }
    }

    // Single line (fallback or explicit single line)
    final List<AlignedSegment> segments = [];
    final chordRegex = RegExp(r'\[ch\](.*?)\[\/ch\]');
    int lastIndex = 0;

    for (final Match match in chordRegex.allMatches(currentLine)) {
      final prefix = currentLine.substring(lastIndex, match.start);
      if (prefix.isNotEmpty) {
        segments.add(AlignedSegment(chord: null, text: prefix));
      }
      segments.add(AlignedSegment(chord: match.group(1)!, text: ''));
      lastIndex = match.end;
    }
    final suffix = currentLine.substring(lastIndex);
    if (suffix.isNotEmpty) {
      segments.add(AlignedSegment(chord: null, text: suffix));
    }

    result.add(AlignedLine(type: AlignedLineType.single, segments: segments));
  }

  return result;
}

class _ChordMatch {
  final String name;
  final int pos;

  _ChordMatch(this.name, this.pos);
}

bool isTabLine(String line) {
  final trimmed = line.trim();
  if (trimmed.length < 10) return false;
  if (!trimmed.contains('|')) return false;
  final dashCount = '-'.allMatches(trimmed).length;
  if (dashCount < 4) return false;

  final tabLineRegex = RegExp(
    r'^\s*([a-gA-G]?[#b]?\||\|)[0-9\-\|\s~/\\()\[\]p+h*rxvbtg\.\u2013\u2014]+$',
    caseSensitive: true,
  );
  return tabLineRegex.hasMatch(trimmed);
}

List<UGPart> _detectTablatureBlocks(UGPart part) {
  if (part.type != UGPartType.text && part.type != UGPartType.tab) {
    return [part];
  }

  final content = part.content;
  final lines = content.split('\n');
  final List<UGPart> result = [];

  int i = 0;
  int lastPartEndIndex = 0;

  while (i < lines.length) {
    int count = 0;
    while (i + count < lines.length && isTabLine(lines[i + count])) {
      count++;
    }

    bool isValidBlock = false;
    int blockSize = 0;

    if (count >= 4 && count <= 9) {
      final blockLines = lines.sublist(i, i + count);
      final lengths = blockLines.map((l) => l.length).toList();
      final minLength = lengths.reduce((a, b) => a < b ? a : b);
      final maxLength = lengths.reduce((a, b) => a > b ? a : b);
      if (maxLength - minLength <= 5) {
        isValidBlock = true;
        blockSize = count;
      }
    } else if (count > 9) {
      for (int size in [6, 7, 8, 4, 5, 9]) {
        if (size <= count) {
          final blockLines = lines.sublist(i, i + size);
          final lengths = blockLines.map((l) => l.length).toList();
          final minLength = lengths.reduce((a, b) => a < b ? a : b);
          final maxLength = lengths.reduce((a, b) => a > b ? a : b);
          if (maxLength - minLength <= 5) {
            isValidBlock = true;
            blockSize = size;
            break;
          }
        }
      }
    }

    if (isValidBlock) {
      if (i > lastPartEndIndex) {
        final textBefore = lines.sublist(lastPartEndIndex, i).join('\n');
        result.add(UGPart(type: part.type, content: textBefore));
      }

      final tablatureContent = lines.sublist(i, i + blockSize).join('\n');
      result.add(UGPart(type: UGPartType.tablature, content: tablatureContent));

      i += blockSize;
      lastPartEndIndex = i;
    } else {
      i++;
    }
  }

  if (lastPartEndIndex < lines.length) {
    final textAfter = lines.sublist(lastPartEndIndex).join('\n');
    result.add(UGPart(type: part.type, content: textAfter));
  }

  return result;
}

String _cleanNewlines(String content) {
  return content.replaceAll(RegExp(r'(\r?\n\s*){3,}'), '\n\n').trim();
}

List<UGPart> parseUGTabs(String content) {
  // Pre-process to clean newlines and ensure chords are tagged
  final cleaned = _cleanNewlines(content);
  final taggedContent = autoTagChords(cleaned);
  final List<UGPart> parts = [];
  int currentPos = 0;

  // Regular expression to find [ch], [tab], and section headers
  final regex = RegExp(
    r'(\[ch\]([\s\S]*?)\[\/ch\]|\[tab\]([\s\S]*?)\[\/tab\]|\[(Intro|Verse|Chorus|Bridge|Outro|Solo|Instrumental|Interlude|Pre-Chorus|Riff|Hook)([\s\S]*?)\])',
    caseSensitive: false,
  );

  for (final Match match in regex.allMatches(taggedContent)) {
    // Add text before the match
    if (match.start > currentPos) {
      parts.add(
        UGPart(
          type: UGPartType.text,
          content: taggedContent.substring(currentPos, match.start),
        ),
      );
    }

    final fullMatch = match.group(0)!;
    final lowerMatch = fullMatch.toLowerCase();

    if (lowerMatch.startsWith('[ch]')) {
      parts.add(UGPart(type: UGPartType.chord, content: match.group(2)!));
    } else if (lowerMatch.startsWith('[tab]')) {
      parts.add(UGPart(type: UGPartType.tab, content: match.group(3)!));
    } else if (fullMatch.startsWith('[')) {
      parts.add(UGPart(type: UGPartType.header, content: fullMatch));
    }

    currentPos = match.end;
  }

  // Add remaining text
  if (currentPos < taggedContent.length) {
    parts.add(
      UGPart(
        type: UGPartType.text,
        content: taggedContent.substring(currentPos),
      ),
    );
  }

  // Post-process parts to extract tablature blocks
  final List<UGPart> finalParts = [];
  for (final part in parts) {
    finalParts.addAll(_detectTablatureBlocks(part));
  }

  return finalParts;
}

List<UGPart> parseGenericTabs(String content) {
  final cleaned = _cleanNewlines(content);
  final lines = cleaned.split('\n');
  final List<UGPart> result = [];

  int i = 0;
  int lastPartEndIndex = 0;

  while (i < lines.length) {
    int count = 0;
    while (i + count < lines.length && isTabLine(lines[i + count])) {
      count++;
    }

    bool isValidBlock = false;
    int blockSize = 0;

    if (count >= 4 && count <= 9) {
      final blockLines = lines.sublist(i, i + count);
      final lengths = blockLines.map((l) => l.length).toList();
      final minLength = lengths.reduce((a, b) => a < b ? a : b);
      final maxLength = lengths.reduce((a, b) => a > b ? a : b);
      if (maxLength - minLength <= 5) {
        isValidBlock = true;
        blockSize = count;
      }
    } else if (count > 9) {
      for (int size in [6, 7, 8, 4, 5, 9]) {
        if (size <= count) {
          final blockLines = lines.sublist(i, i + size);
          final lengths = blockLines.map((l) => l.length).toList();
          final minLength = lengths.reduce((a, b) => a < b ? a : b);
          final maxLength = lengths.reduce((a, b) => a > b ? a : b);
          if (maxLength - minLength <= 5) {
            isValidBlock = true;
            blockSize = size;
            break;
          }
        }
      }
    }

    if (isValidBlock) {
      if (i > lastPartEndIndex) {
        final textBefore = lines.sublist(lastPartEndIndex, i).join('\n');
        result.add(UGPart(type: UGPartType.text, content: textBefore));
      }

      final tablatureContent = lines.sublist(i, i + blockSize).join('\n');
      result.add(UGPart(type: UGPartType.tablature, content: tablatureContent));

      i += blockSize;
      lastPartEndIndex = i;
    } else {
      i++;
    }
  }

  if (lastPartEndIndex < lines.length) {
    final textAfter = lines.sublist(lastPartEndIndex).join('\n');
    result.add(UGPart(type: UGPartType.text, content: textAfter));
  }

  return result;
}
