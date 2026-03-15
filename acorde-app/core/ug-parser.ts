export interface UGPart {
  type: 'text' | 'chord' | 'header' | 'tab';
  content: string;
}

export function isUGFormat(content: string): boolean {
  if (!content) return false;
  // Check for exact tags or common header patterns
  const hasTags = content.includes('[ch]') || content.includes('[tab]');
  if (hasTags) return true;

  const headerPattern = /\[(Intro|Verse|Chorus|Bridge|Outro|Solo|Instrumental|Interlude|Pre-Chorus|Riff|Hook)/i;
  return headerPattern.test(content);
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
