export interface UGPart {
  type: 'text' | 'chord' | 'header' | 'tab';
  content: string;
}

export interface AlignedSegment {
  chord: string | null;
  text: string;
}

export interface AlignedLine {
  type: 'paired' | 'single';
  segments: AlignedSegment[];
}

export function isUGFormat(content: string): boolean {
  if (!content) return false;
  // Check for exact tags or common header patterns
  const hasTags = content.includes('[ch]') || content.includes('[tab]');
  if (hasTags) return true;

  const headerPattern = /\[(Intro|Verse|Chorus|Bridge|Outro|Solo|Instrumental|Interlude|Pre-Chorus|Riff|Hook)/i;
  if (headerPattern.test(content)) return true;

  // If it has lines that look like chords but no tags
  const lines = content.split('\n');
  for (const line of lines) {
    if (isChordOnlyLine(line)) return true;
  }

  return false;
}

// Shared chord pattern: A-G, optional # or b, optional m, maj, 7, sus, etc.
// Using a non-global regex for testing individual words to avoid lastIndex issues
const CHORD_SYMBOL_REGEX = /^[A-G][#b]?(?:m|maj|min|aug|dim|sus|add|[0-9]|M)*(?:\/[A-G][#b]?(?:m|maj|min|aug|dim|sus|add|[0-9]|M)*)?$/i;

function isChordOnlyLine(line: string): boolean {
  const trimmed = line.trim();
  if (!trimmed) return false;
  
  // Remove common separators and brackets that might be in a chord line
  const lineWithoutSeparators = trimmed.replace(/[|()\[\]\-\u2013\u2014]/g, ' ');
  const words = lineWithoutSeparators.trim().split(/\s+/);
  if (words.length === 0) return false;

  let chordCount = 0;
  for (const word of words) {
    if (!word) continue;
    
    if (CHORD_SYMBOL_REGEX.test(word)) {
      chordCount++;
    } else {
      // If any word is clearly not a chord and not a simple character, it's probably not a chord-only line
      // Allow for some common short strings in chord lines like "x2", "NC", etc.
      if (word.length > 2 && word.toUpperCase() !== 'N.C.' && word.toUpperCase() !== 'NC') return false;
    }
  }

  return chordCount > 0;
}

/**
 * Pre-processes content to wrap untagged chords in [ch] tags.
 */
export function autoTagChords(content: string): string {
  if (content.includes('[ch]')) return content; // Already tagged

  const lines = content.split('\n');

  const processedLines = lines.map(line => {
    // If it's a header or already contains tags, leave it
    const trimmed = line.trim();
    if (trimmed.startsWith('[') || line.includes('[tab]')) return line;

    // Check if it's a tab line (contains |-)
    if (line.includes('|-')) return line;

    // We split the line by everything that is NOT a word character or / #
    // to isolate potential chord symbols but keep the spacing/punctuation
    const segments = line.split(/([^a-zA-Z0-9/#]+)/);
    
    let chordMatchesCount = 0;
    let wordCount = 0;
    
    const processedSegments = segments.map(seg => {
      // If it's a separator, return it as is
      if (!seg || /[^a-zA-Z0-9/#]/.test(seg)) return seg;
      
      // Heuristic: If it looks like a string indicator (e.g., E- at start of line or near |)
      // but CHORD_SYMBOL_REGEX will match E. We need to be careful.
      // If it's part of a tab line structure (already handled by |- check above, 
      // but let's be more specific for single letters if they are followed by | or -)
      
      wordCount++;
      if (CHORD_SYMBOL_REGEX.test(seg)) {
        chordMatchesCount++;
        return `[ch]${seg}[/ch]`;
      }
      return seg;
    });

    if (chordMatchesCount > 0 && (isChordOnlyLine(line) || chordMatchesCount / wordCount >= 0.5)) {
      return processedSegments.join('');
    }

    return line;
  });

  return processedLines.join('\n');
}

export function parseAlignedSegments(content: string): AlignedLine[] {
  // Ensure chords are tagged before alignment
  const taggedContent = autoTagChords(content);
  const lines = taggedContent.split('\n');
  const result: AlignedLine[] = [];
  
  for (let i = 0; i < lines.length; i++) {
    const currentLine = lines[i];
    const nextLine = lines[i + 1];
    
    // Check if current line contains chords and next line is a text line (not headers/tags)
    const hasChords = currentLine.includes('[ch]');
    const nextIsLyrics = nextLine !== undefined && !nextLine.includes('[ch]') && !nextLine.includes('[') && nextLine.trim().length > 0;
    
    if (hasChords && nextIsLyrics) {
      // It's a pair!
      const segments: AlignedSegment[] = [];
      
      const chords: { name: string, pos: number }[] = [];
      const chordRegex = /\[ch\](.*?)\[\/ch\]/g;
      let match;
      let lastIndex = 0;
      let charPos = 0;
      
      while ((match = chordRegex.exec(currentLine)) !== null) {
        const prefix = currentLine.substring(lastIndex, match.index);
        charPos += prefix.length;
        chords.push({ name: match[1], pos: charPos });
        lastIndex = chordRegex.lastIndex;
      }
      
      if (chords.length > 0) {
        if (chords[0].pos > 0) {
          segments.push({ chord: null, text: nextLine.substring(0, chords[0].pos) });
        }

        for (let j = 0; j < chords.length; j++) {
          const chord = chords[j];
          const nextChordPos = chords[j + 1] ? chords[j + 1].pos : Math.max(nextLine.length, currentLine.length);
          segments.push({ chord: chord.name, text: nextLine.substring(chord.pos, nextChordPos) });
        }
        
        result.push({ type: 'paired', segments });
        i++; // Skip paired line
        continue;
      }
    }
    
    // Single line (fallback or explicit single line)
    const segments: AlignedSegment[] = [];
    const chordRegex = /\[ch\](.*?)\[\/ch\]/g;
    let match;
    let lastIndex = 0;
    
    let hasExplicitChords = false;
    while ((match = chordRegex.exec(currentLine)) !== null) {
      hasExplicitChords = true;
      const prefix = currentLine.substring(lastIndex, match.index);
      if (prefix) segments.push({ chord: null, text: prefix });
      segments.push({ chord: match[1], text: '' });
      lastIndex = chordRegex.lastIndex;
    }
    const suffix = currentLine.substring(lastIndex);
    if (suffix) segments.push({ chord: null, text: suffix });
    
    result.push({ type: 'single', segments });
  }
  
  return result;
}

export function parseUGTabs(content: string): UGPart[] {
  // Pre-process to ensure chords are tagged
  const taggedContent = autoTagChords(content);
  const parts: UGPart[] = [];
  let currentPos = 0;
  
  // Regular expression to find [ch], [tab], and section headers
  // Using [\s\S] to match newlines inside tags
  const regex = /(\[ch\]([\s\S]*?)\[\/ch\]|\[tab\]([\s\S]*?)\[\/tab\]|\[(Intro|Verse|Chorus|Bridge|Outro|Solo|Instrumental|Interlude|Pre-Chorus|Riff|Hook)([\s\S]*?)\])/gi;
  
  let match;
  while ((match = regex.exec(taggedContent)) !== null) {
    // Add text before the match
    if (match.index > currentPos) {
      parts.push({
        type: 'text',
        content: taggedContent.substring(currentPos, match.index)
      });
    }
    
    const fullMatch = match[0];
    const lowerMatch = fullMatch.toLowerCase();
    
    if (lowerMatch.startsWith('[ch]')) {
      parts.push({
        type: 'chord',
        content: match[2]
      });
    } else if (lowerMatch.startsWith('[tab]')) {
      parts.push({
        type: 'tab',
        content: match[3]
      });
    } else if (fullMatch.startsWith('[')) {
      parts.push({
        type: 'header',
        content: fullMatch
      });
    }
    
    currentPos = regex.lastIndex;
  }
  
  // Add remaining text
  if (currentPos < taggedContent.length) {
    parts.push({
      type: 'text',
      content: taggedContent.substring(currentPos)
    });
  }
  
  return parts;
}
