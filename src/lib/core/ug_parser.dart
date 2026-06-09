enum UGPartType { text, chord, header, tab }

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
      int charPos = 0;
      int lastIndex = 0;

      for (final Match match in chordRegex.allMatches(currentLine)) {
        final prefix = currentLine.substring(lastIndex, match.start);
        charPos += prefix.length;
        chords.add(_ChordMatch(match.group(1)!, charPos));
        lastIndex = match.end;
      }

      if (chords.isNotEmpty) {
        if (chords[0].pos > 0) {
          segments.add(
            AlignedSegment(
              chord: null,
              text: nextLine.substring(0, chords[0].pos),
            ),
          );
        }

        for (int j = 0; j < chords.length; j++) {
          final chord = chords[j];
          final nextChordPos = (j + 1 < chords.length)
              ? chords[j + 1].pos
              : (nextLine.length > currentLine.length
                    ? nextLine.length
                    : currentLine.length);

          final startIdx = chord.pos < nextLine.length
              ? chord.pos
              : nextLine.length;
          final endIdx = nextChordPos < nextLine.length
              ? nextChordPos
              : nextLine.length;

          segments.add(
            AlignedSegment(
              chord: chord.name,
              text: nextLine.substring(startIdx, endIdx),
            ),
          );
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

List<UGPart> parseUGTabs(String content) {
  // Pre-process to ensure chords are tagged
  final taggedContent = autoTagChords(content);
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

  return parts;
}
