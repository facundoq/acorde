export interface ChordShape {
  name: string;
  frets: number[]; // -1 for muted, 0 for open, 1-24 for frets
  fingers?: number[]; // 0 for none, 1-4 for fingers
  barre?: number; // fret number for barre
}

export const CHORD_SHAPES: Record<string, ChordShape[]> = {
  'C': [
    { name: 'C', frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0] },
    { name: 'C', frets: [-1, 3, 5, 5, 5, 3], fingers: [0, 1, 3, 3, 3, 1], barre: 3 },
    { name: 'C', frets: [-1, 8, 10, 10, 9, 8], fingers: [0, 1, 3, 4, 2, 1], barre: 8 },
  ],
  'C/G': [
    { name: 'C/G', frets: [3, 3, 2, 0, 1, 0], fingers: [3, 4, 2, 0, 1, 0] },
  ],
  'C/E': [
    { name: 'C/E', frets: [0, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0] },
  ],
  'Cadd4': [
    { name: 'Cadd4', frets: [-1, 3, 3, 0, 1, 0], fingers: [0, 2, 3, 0, 1, 0] },
  ],
  'Cadd9': [
    { name: 'Cadd9', frets: [-1, 3, 2, 0, 3, 0], fingers: [0, 2, 1, 0, 3, 0] },
    { name: 'Cadd9', frets: [-1, 3, 2, 0, 3, 3], fingers: [0, 2, 1, 0, 3, 4] },
  ],
  'C#': [
    { name: 'C#', frets: [-1, 4, 6, 6, 6, 4], fingers: [0, 1, 3, 3, 3, 1], barre: 4 },
    { name: 'C#', frets: [-1, -1, 3, 1, 2, 1], fingers: [0, 0, 3, 1, 2, 1], barre: 1 },
  ],
  'C#/G#': [
    { name: 'C#/G#', frets: [4, 4, 6, 6, 6, 4], fingers: [1, 1, 2, 3, 4, 1], barre: 4 },
  ],
  'Db': [
    { name: 'Db', frets: [-1, 4, 6, 6, 6, 4], fingers: [0, 1, 3, 3, 3, 1], barre: 4 },
  ],
  'D': [
    { name: 'D', frets: [-1, -1, 0, 2, 3, 2], fingers: [0, 0, 0, 1, 3, 2] },
    { name: 'D', frets: [-1, 5, 7, 7, 7, 5], fingers: [0, 1, 3, 3, 3, 1], barre: 5 },
    { name: 'D', frets: [-1, 10, 12, 12, 11, 10], fingers: [0, 1, 3, 4, 2, 1], barre: 10 },
  ],
  'D/F#': [
    { name: 'D/F#', frets: [2, 0, 0, 2, 3, 2], fingers: [1, 0, 0, 2, 4, 3] },
    { name: 'D/F#', frets: [2, -1, 0, 2, 3, 2], fingers: [1, 0, 0, 2, 4, 3] },
  ],
  'Dsus2': [
    { name: 'Dsus2', frets: [-1, -1, 0, 2, 3, 0], fingers: [0, 0, 0, 1, 3, 0] },
  ],
  'Dsus4': [
    { name: 'Dsus4', frets: [-1, -1, 0, 2, 3, 3], fingers: [0, 0, 0, 1, 2, 4] },
  ],
  'D#': [
    { name: 'D#', frets: [-1, 6, 8, 8, 8, 6], fingers: [0, 1, 3, 3, 3, 1], barre: 6 },
  ],
  'D#/A#': [
    { name: 'D#/A#', frets: [-1, 1, 1, 3, 4, 3], fingers: [0, 1, 1, 2, 4, 3], barre: 1 },
  ],
  'D#7/A#': [
    { name: 'D#7/A#', frets: [-1, 1, 1, 3, 2, 3], fingers: [0, 1, 1, 3, 2, 4], barre: 1 },
  ],
  'Eb': [
    { name: 'Eb', frets: [-1, 6, 8, 8, 8, 6], fingers: [0, 1, 3, 3, 3, 1], barre: 6 },
    { name: 'Eb', frets: [-1, -1, 5, 3, 4, 3], fingers: [0, 0, 3, 1, 2, 1], barre: 3 },
  ],
  'E': [
    { name: 'E', frets: [0, 2, 2, 1, 0, 0], fingers: [0, 2, 3, 1, 0, 0] },
    { name: 'E', frets: [-1, 7, 9, 9, 9, 7], fingers: [0, 1, 3, 3, 3, 1], barre: 7 },
    { name: 'E', frets: [0, 7, 6, 4, 5, 4], fingers: [0, 4, 3, 1, 2, 1], barre: 4 },
  ],
  'Esus4': [
    { name: 'Esus4', frets: [0, 2, 2, 2, 0, 0], fingers: [0, 2, 3, 4, 0, 0] },
  ],
  'F': [
    { name: 'F', frets: [1, 3, 3, 2, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1 },
    { name: 'F', frets: [-1, 8, 10, 10, 10, 8], fingers: [0, 1, 3, 3, 3, 1], barre: 8 },
  ],
  'F/A': [
    { name: 'F/A', frets: [-1, 0, 3, 2, 1, 1], fingers: [0, 0, 3, 2, 1, 1], barre: 1 },
    { name: 'F/A', frets: [5, 3, 3, 2, 1, 1], fingers: [4, 3, 3, 2, 1, 1], barre: 1 },
  ],
  'Fsus4': [
    { name: 'Fsus4', frets: [1, 3, 3, 3, 1, 1], fingers: [1, 3, 4, 2, 1, 1], barre: 1 },
    { name: 'Fsus4', frets: [-1, 8, 10, 10, 11, 8], fingers: [0, 1, 3, 4, 2, 1], barre: 8 },
  ],
  'F7': [
    { name: 'F7', frets: [1, 3, 1, 2, 1, 1], fingers: [1, 3, 1, 2, 1, 1], barre: 1 },
  ],
  'F#': [
    { name: 'F#', frets: [2, 4, 4, 3, 2, 2], fingers: [1, 3, 4, 2, 1, 1], barre: 2 },
  ],
  'Gb': [
    { name: 'Gb', frets: [2, 4, 4, 3, 2, 2], fingers: [1, 3, 4, 2, 1, 1], barre: 2 },
  ],
  'G': [
    { name: 'G', frets: [3, 2, 0, 0, 0, 3], fingers: [3, 2, 0, 0, 0, 4] },
    { name: 'G', frets: [3, 5, 5, 4, 3, 3], fingers: [1, 3, 4, 2, 1, 1], barre: 3 },
    { name: 'G', frets: [-1, 10, 12, 12, 12, 10], fingers: [0, 1, 3, 3, 3, 1], barre: 10 },
  ],
  'G/B': [
    { name: 'G/B', frets: [-1, 2, 0, 0, 3, 3], fingers: [0, 1, 0, 0, 3, 4] },
    { name: 'G/B', frets: [7, 5, 5, 4, 3, 3], fingers: [4, 2, 3, 1, 1, 1], barre: 3 },
  ],
  'Gsus4': [
    { name: 'Gsus4', frets: [3, 3, 0, 0, 3, 3], fingers: [1, 1, 0, 0, 3, 4], barre: 3 },
  ],
  'G#': [
    { name: 'G#', frets: [4, 6, 6, 5, 4, 4], fingers: [1, 3, 4, 2, 1, 1], barre: 4 },
  ],
  'G#/C': [
    { name: 'G#/C', frets: [-1, 3, 1, 1, 1, -1], fingers: [0, 3, 1, 1, 1, 0], barre: 1 },
  ],
  'Ab': [
    { name: 'Ab', frets: [4, 6, 6, 5, 4, 4], fingers: [1, 3, 4, 2, 1, 1], barre: 4 },
  ],
  'A': [
    { name: 'A', frets: [-1, 0, 2, 2, 2, 0], fingers: [0, 0, 1, 2, 3, 0] },
    { name: 'A', frets: [5, 7, 7, 6, 5, 5], fingers: [1, 3, 4, 2, 1, 1], barre: 5 },
    { name: 'A', frets: [-1, 12, 14, 14, 14, 12], fingers: [0, 1, 3, 3, 3, 1], barre: 12 },
  ],
  'Asus2': [
    { name: 'Asus2', frets: [-1, 0, 2, 2, 0, 0], fingers: [0, 0, 1, 2, 0, 0] },
  ],
  'Asus4': [
    { name: 'Asus4', frets: [-1, 0, 2, 2, 3, 0], fingers: [0, 0, 1, 2, 3, 0] },
  ],
  'A6': [
    { name: 'A6', frets: [-1, 0, 2, 2, 2, 2], fingers: [0, 0, 1, 1, 1, 1], barre: 2 },
  ],
  'A#': [
    { name: 'A#', frets: [-1, 1, 3, 3, 3, 1], fingers: [0, 1, 3, 3, 3, 1], barre: 1 },
  ],
  'A#m': [
    { name: 'A#m', frets: [-1, 1, 3, 3, 2, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1 },
  ],
  'Bb': [
    { name: 'Bb', frets: [-1, 1, 3, 3, 3, 1], fingers: [0, 1, 3, 3, 3, 1], barre: 1 },
    { name: 'Bb', frets: [6, 8, 8, 7, 6, 6], fingers: [1, 3, 4, 2, 1, 1], barre: 6 },
  ],
  'B': [
    { name: 'B', frets: [-1, 2, 4, 4, 4, 2], fingers: [0, 1, 3, 3, 3, 1], barre: 2 },
    { name: 'B', frets: [7, 9, 9, 8, 7, 7], fingers: [1, 3, 4, 2, 1, 1], barre: 7 },
  ],
  'B/F#': [
    { name: 'B/F#', frets: [2, 2, 4, 4, 4, 2], fingers: [1, 1, 2, 3, 4, 1], barre: 2 },
  ],
  'B/A#': [
    { name: 'B/A#', frets: [-1, 1, 4, 4, 4, 2], fingers: [0, 1, 3, 3, 3, 1], barre: 1 },
  ],
  'Bsus4': [
    { name: 'Bsus4', frets: [-1, 2, 4, 4, 5, 2], fingers: [0, 1, 3, 4, 2, 1], barre: 2 },
  ],
  'B#': [
    { name: 'B#', frets: [-1, 3, 2, 0, 1, 0], fingers: [0, 3, 2, 0, 1, 0] }, // Same as C
  ],
  'Cm': [
    { name: 'Cm', frets: [-1, 3, 5, 5, 4, 3], fingers: [0, 1, 3, 4, 2, 1], barre: 3 },
  ],
  'C#m': [
    { name: 'C#m', frets: [-1, 4, 6, 6, 5, 4], fingers: [0, 1, 3, 4, 2, 1], barre: 4 },
  ],
  'C#mM7': [
    { name: 'C#mM7', frets: [-1, 4, 6, 5, 5, 4], fingers: [0, 1, 4, 2, 3, 1], barre: 4 },
  ],
  'C#m7': [
    { name: 'C#m7', frets: [-1, 4, 6, 4, 5, 4], fingers: [0, 1, 3, 1, 2, 1], barre: 4 },
  ],
  'C#m6': [
    { name: 'C#m6', frets: [-1, 4, 2, 3, 2, -1], fingers: [0, 3, 1, 2, 1, 0], barre: 2 },
  ],
  'C#m/B': [
    { name: 'C#m/B', frets: [-1, 2, 2, 1, 2, 0], fingers: [0, 2, 3, 1, 4, 0] },
  ],
  'Dm': [
    { name: 'Dm', frets: [-1, -1, 0, 2, 3, 1], fingers: [0, 0, 0, 2, 3, 1] },
  ],
  'D#m': [
    { name: 'D#m', frets: [-1, 6, 8, 8, 7, 6], fingers: [0, 1, 3, 4, 2, 1], barre: 6 },
  ],
  'Em': [
    { name: 'Em', frets: [0, 2, 2, 0, 0, 0], fingers: [0, 2, 3, 0, 0, 0] },
  ],
  'Em7': [
    { name: 'Em7', frets: [0, 2, 0, 0, 0, 0], fingers: [0, 2, 0, 0, 0, 0] },
  ],
  'Ebm': [
    { name: 'Ebm', frets: [-1, 6, 8, 8, 7, 6], fingers: [0, 1, 3, 4, 2, 1], barre: 6 },
  ],
  'F#m': [
    { name: 'F#m', frets: [2, 4, 4, 2, 2, 2], fingers: [1, 3, 4, 1, 1, 1], barre: 2 },
  ],
  'G#m': [
    { name: 'G#m', frets: [4, 6, 6, 4, 4, 4], fingers: [1, 3, 4, 1, 1, 1], barre: 4 },
  ],
  'Bbm': [
    { name: 'Bbm', frets: [-1, 1, 3, 3, 2, 1], fingers: [0, 1, 3, 4, 2, 1], barre: 1 },
  ],
  'Am': [
    { name: 'Am', frets: [-1, 0, 2, 2, 1, 0], fingers: [0, 0, 2, 3, 1, 0] },
  ],
  'Am/G': [
    { name: 'Am/G', frets: [3, 0, 2, 2, 1, 0], fingers: [4, 0, 2, 3, 1, 0] },
  ],
  'Am/F#': [
    { name: 'Am/F#', frets: [2, 0, 2, 2, 1, 0], fingers: [2, 0, 3, 4, 1, 0] },
  ],
  'Am7': [
    { name: 'Am7', frets: [-1, 0, 2, 0, 1, 0], fingers: [0, 0, 2, 0, 1, 0] },
  ],
  'Am9': [
    { name: 'Am9', frets: [-1, 0, 2, 0, 0, 0], fingers: [0, 0, 2, 0, 0, 0] },
  ],
  'Bm': [
    { name: 'Bm', frets: [-1, 2, 4, 4, 3, 2], fingers: [0, 1, 3, 4, 2, 1], barre: 2 },
    { name: 'Bm', frets: [7, 9, 9, 7, 7, 7], fingers: [1, 3, 4, 1, 1, 1], barre: 7 },
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
