export interface ChordShape {
  name: string;
  frets: number[]; // -1 for muted, 0 for open, 1-24 for frets
  fingers?: number[]; // 0 for none, 1-4 for fingers
  barre?: number; // fret number for barre
}

export const CHORD_SHAPES: Record<string, ChordShape[]> = {
  'C': [
    { name: 'C', frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0] },
    { name: 'C', frets: [-1, 3, 5, 5, 5, 3], fingers: [0, 1, 2, 3, 4, 1], barre: 3 },
  ],
  'D': [
    { name: 'D', frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2] },
  ],
  'E': [
    { name: 'E', frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0] },
  ],
  'G': [
    { name: 'G', frets: [3, 2, 0, 0, 0, 3], fingers: [3, 2, 0, 0, 0, 4] },
  ],
  'A': [
    { name: 'A', frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0] },
  ],
  'Am': [
    { name: 'Am', frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0] },
  ],
  'Am7': [
    { name: 'Am7', frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0] },
  ],
  'Am9': [
    { name: 'Am9', frets: [-1, 0, 2, 0, 0, 0], fingers: [0, 0, 2, 0, 0, 0] },
  ],
  'Em': [
    { name: 'Em', frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0] },
  ],
  'Em7': [
    { name: 'Em7', frets: [0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0] },
  ],
  'Dm': [
    { name: 'Dm', frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1] },
  ],
  'Dsus2': [
    { name: 'Dsus2', frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 3, 0] },
  ],
  'Dsus4': [
    { name: 'Dsus4', frets: [-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 2, 4] },
  ],
  'Gsus4': [
    { name: 'Gsus4', frets: [3, 3, 0, 0, 3, 3], fingers: [1, 1, 0, 0, 3, 4], barre: 3 },
  ],
  'Asus2': [
    { name: 'Asus2', frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0] },
  ],
  'Asus4': [
    { name: 'Asus4', frets: [-1, 0, 2, 2, 3, 0], fingers: [0, 0, 1, 2, 3, 0] },
  ],
  'Csus2': [
    { name: 'Csus2', frets: [-1, 3, 0, 0, 1, 0], fingers: [0, 3, 0, 0, 1, 0] },
  ],
  'Csus4': [
    { name: 'Csus4', frets: [-1, 3, 3, 0, 1, 1], fingers: [0, 3, 4, 0, 1, 1] },
  ],
  'F': [
    { name: 'F', frets: [1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1 },
  ],
  'B': [
    { name: 'B', frets: [-1, 2, 4, 4, 4, 2], fingers: [0, 1, 2, 3, 4, 1], barre: 2 },
  ],
  'Bm': [
    { name: 'Bm', frets: [-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], barre: 2 },
  ],
  'C7': [
    { name: 'C7', frets: [-1, 3, 2, 3, 1, 0], fingers: [0, 3, 2, 4, 1, 0] },
  ],
  'D7': [
    { name: 'D7', frets: [-1, -1, 0, 2, 1, 2], fingers: [0, 0, 0, 2, 1, 3] },
  ],
  'E7': [
    { name: 'E7', frets: [0, 2, 0, 1, 0, 0], fingers: [0, 2, 0, 1, 0, 0] },
  ],
  'G7': [
    { name: 'G7', frets: [3, 2, 0, 0, 0, 1], fingers: [3, 2, 0, 0, 0, 1] },
  ],
  'A7': [
    { name: 'A7', frets: [-1, 0, 2, 0, 2, 0], fingers: [0, 0, 1, 0, 2, 0] },
  ],
  'F#m': [
    { name: 'F#m', frets: [2, 4, 4, 2, 2, 2], fingers: [1, 3, 4, 1, 1, 1], barre: 2 },
  ],
  'G#m': [
    { name: 'G#m', frets: [4, 6, 6, 4, 4, 4], fingers: [1, 3, 4, 1, 1, 1], barre: 4 },
  ],
  'C#m': [
    { name: 'C#m', frets: [-1, 4, 6, 6, 5, 4], fingers: [0, 1, 3, 4, 2, 1], barre: 4 },
  ],
};

export function getChordShapes(name: string): ChordShape[] {
  if (!name) return [];
  
  // Try exact match first
  if (CHORD_SHAPES[name]) return CHORD_SHAPES[name];

  // Try case-insensitive match
  const lowerName = name.toLowerCase();
  const foundKey = Object.keys(CHORD_SHAPES).find(k => k.toLowerCase() === lowerName);
  
  if (foundKey) return CHORD_SHAPES[foundKey];
  
  return [];
}

export function getChordShape(name: string): ChordShape | null {
  const shapes = getChordShapes(name);
  return shapes.length > 0 ? shapes[0] : null;
}
