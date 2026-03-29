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
  return headerPattern.test(content);
}

export function parseAlignedSegments(content: string): AlignedLine[] {
  const lines = content.split('\n');
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
    } else {
      // Single line
      const segments: AlignedSegment[] = [];
      const chordRegex = /\[ch\](.*?)\[\/ch\]/g;
      let match;
      let lastIndex = 0;
      
      while ((match = chordRegex.exec(currentLine)) !== null) {
        const prefix = currentLine.substring(lastIndex, match.index);
        if (prefix) segments.push({ chord: null, text: prefix });
        segments.push({ chord: match[1], text: '' });
        lastIndex = chordRegex.lastIndex;
      }
      const suffix = currentLine.substring(lastIndex);
      if (suffix) segments.push({ chord: null, text: suffix });
      
      result.push({ type: 'single', segments });
    }
  }
  
  return result;
}

export function parseUGTabs(content: string): UGPart[] {
  const parts: UGPart[] = [];
  let currentPos = 0;
  
  // Regular expression to find [ch], [tab], and section headers
  // Using [\s\S] to match newlines inside tags
  const regex = /(\[ch\]([\s\S]*?)\[\/ch\]|\[tab\]([\s\S]*?)\[\/tab\]|\[(Intro|Verse|Chorus|Bridge|Outro|Solo|Instrumental|Interlude|Pre-Chorus|Riff|Hook)([\s\S]*?)\])/gi;
  
  let match;
  while ((match = regex.exec(content)) !== null) {
    // Add text before the match
    if (match.index > currentPos) {
      parts.push({
        type: 'text',
        content: content.substring(currentPos, match.index)
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
  if (currentPos < content.length) {
    parts.push({
      type: 'text',
      content: content.substring(currentPos)
    });
  }
  
  return parts;
}
