// Generated file. Do not edit manually.

class ChordShape {
  final String name;
  final List<int> frets;
  final List<int>? fingers;
  final int? barre;

  const ChordShape({
    required this.name,
    required this.frets,
    this.fingers,
    this.barre,
  });
}

const Map<String, List<ChordShape>> chordShapes = {
  'C': [
    ChordShape(
      name: 'C',
      frets: [-1, 3, 2, 0, 1, 0],
      fingers: [0, 3, 2, 0, 1, 0],
    ),
    ChordShape(
      name: 'C',
      frets: [-1, 3, 5, 5, 5, 3],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 3,
    ),
    ChordShape(
      name: 'C',
      frets: [-1, 8, 10, 10, 9, 8],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 8,
    ),
  ],
  'Csus2': [
    ChordShape(
      name: 'Csus2',
      frets: [-1, 3, 5, 5, 3, 3],
      fingers: [0, 1, 3, 4, 1, 1],
      barre: 3,
    ),
  ],
  'Csus4': [
    ChordShape(
      name: 'Csus4',
      frets: [-1, 3, 5, 5, 6, 3],
      fingers: [0, 1, 3, 4, 4, 1],
      barre: 3,
    ),
  ],
  'C5': [
    ChordShape(
      name: 'C5',
      frets: [-1, 3, 5, 5, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'C9': [
    ChordShape(
      name: 'C9',
      frets: [-1, 3, 2, 3, 3, 3],
      fingers: [0, 2, 1, 3, 3, 3],
      barre: 3,
    ),
  ],
  'Cm9': [
    ChordShape(
      name: 'Cm9',
      frets: [-1, 3, 1, 3, 3, -1],
      fingers: [0, 3, 1, 4, 4, 0],
      barre: 3,
    ),
  ],
  'C/G': [
    ChordShape(
      name: 'C/G',
      frets: [3, 3, 2, 0, 1, 0],
      fingers: [3, 4, 2, 0, 1, 0],
    ),
  ],
  'C/E': [
    ChordShape(
      name: 'C/E',
      frets: [0, 3, 2, 0, 1, 0],
      fingers: [0, 3, 2, 0, 1, 0],
    ),
  ],
  'Cadd4': [
    ChordShape(
      name: 'Cadd4',
      frets: [-1, 3, 3, 0, 1, 0],
      fingers: [0, 2, 3, 0, 1, 0],
    ),
  ],
  'Cadd9': [
    ChordShape(
      name: 'Cadd9',
      frets: [-1, 3, 2, 0, 3, 0],
      fingers: [0, 2, 1, 0, 3, 0],
    ),
    ChordShape(
      name: 'Cadd9',
      frets: [-1, 3, 2, 0, 3, 3],
      fingers: [0, 2, 1, 0, 3, 4],
    ),
  ],
  'Cadd11': [
    ChordShape(
      name: 'Cadd11',
      frets: [-1, 3, 3, 0, 1, 0],
      fingers: [0, 3, 4, 0, 1, 0],
    ),
    ChordShape(
      name: 'Cadd11',
      frets: [-1, 3, 3, 5, 5, 3],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 3,
    ),
  ],
  'C#': [
    ChordShape(
      name: 'C#',
      frets: [-1, 4, 6, 6, 6, 4],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 4,
    ),
    ChordShape(
      name: 'C#',
      frets: [-1, -1, 3, 1, 2, 1],
      fingers: [0, 0, 3, 1, 2, 1],
      barre: 1,
    ),
  ],
  'C#sus2': [
    ChordShape(
      name: 'C#sus2',
      frets: [-1, 4, 6, 6, 4, 4],
      fingers: [0, 1, 3, 4, 1, 1],
      barre: 4,
    ),
  ],
  'C#sus4': [
    ChordShape(
      name: 'C#sus4',
      frets: [-1, 4, 6, 6, 7, 4],
      fingers: [0, 1, 3, 4, 4, 1],
      barre: 4,
    ),
  ],
  'C#5': [
    ChordShape(
      name: 'C#5',
      frets: [-1, 4, 6, 6, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'C#9': [
    ChordShape(
      name: 'C#9',
      frets: [-1, 4, 3, 4, 4, 4],
      fingers: [0, 2, 1, 3, 3, 3],
      barre: 4,
    ),
  ],
  'C#m9': [
    ChordShape(
      name: 'C#m9',
      frets: [-1, 4, 2, 4, 4, -1],
      fingers: [0, 3, 1, 4, 4, 0],
      barre: 4,
    ),
  ],
  'C#/G#': [
    ChordShape(
      name: 'C#/G#',
      frets: [4, 4, 6, 6, 6, 4],
      fingers: [1, 1, 2, 3, 4, 1],
      barre: 4,
    ),
  ],
  'C#add11': [
    ChordShape(
      name: 'C#add11',
      frets: [-1, 4, 4, 6, 6, 4],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 4,
    ),
  ],
  'Db': [
    ChordShape(
      name: 'Db',
      frets: [-1, 4, 6, 6, 6, 4],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 4,
    ),
  ],
  'Dbadd11': [
    ChordShape(
      name: 'Dbadd11',
      frets: [-1, 4, 4, 6, 6, 4],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 4,
    ),
  ],
  'D': [
    ChordShape(
      name: 'D',
      frets: [-1, -1, 0, 2, 3, 2],
      fingers: [0, 0, 0, 1, 3, 2],
    ),
    ChordShape(
      name: 'D',
      frets: [-1, 5, 7, 7, 7, 5],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 5,
    ),
    ChordShape(
      name: 'D',
      frets: [-1, 10, 12, 12, 11, 10],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 10,
    ),
  ],
  'D5': [
    ChordShape(
      name: 'D5',
      frets: [-1, -1, 0, 2, 3, -1],
      fingers: [0, 0, 0, 1, 2, 0],
    ),
    ChordShape(
      name: 'D5',
      frets: [-1, 5, 7, 7, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'D9': [
    ChordShape(
      name: 'D9',
      frets: [-1, 5, 4, 5, 5, 5],
      fingers: [0, 2, 1, 3, 3, 3],
      barre: 5,
    ),
  ],
  'Dm9': [
    ChordShape(
      name: 'Dm9',
      frets: [-1, 5, 3, 5, 5, -1],
      fingers: [0, 3, 1, 4, 4, 0],
      barre: 5,
    ),
  ],
  'D/F#': [
    ChordShape(
      name: 'D/F#',
      frets: [2, 0, 0, 2, 3, 2],
      fingers: [1, 0, 0, 2, 4, 3],
    ),
    ChordShape(
      name: 'D/F#',
      frets: [2, -1, 0, 2, 3, 2],
      fingers: [1, 0, 0, 2, 4, 3],
    ),
  ],
  'Dsus2': [
    ChordShape(
      name: 'Dsus2',
      frets: [-1, -1, 0, 2, 3, 0],
      fingers: [0, 0, 0, 1, 3, 0],
    ),
  ],
  'Dsus4': [
    ChordShape(
      name: 'Dsus4',
      frets: [-1, -1, 0, 2, 3, 3],
      fingers: [0, 0, 0, 1, 2, 4],
    ),
  ],
  'Dadd11': [
    ChordShape(
      name: 'Dadd11',
      frets: [-1, -1, 0, 0, 3, 2],
      fingers: [0, 0, 0, 0, 3, 2],
    ),
    ChordShape(
      name: 'Dadd11',
      frets: [-1, 5, 4, 0, 3, 5],
      fingers: [0, 3, 2, 0, 1, 4],
    ),
    ChordShape(
      name: 'Dadd11',
      frets: [-1, 5, 5, 7, 7, 5],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 5,
    ),
  ],
  'D#': [
    ChordShape(
      name: 'D#',
      frets: [-1, 6, 8, 8, 8, 6],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 6,
    ),
  ],
  'D#sus2': [
    ChordShape(
      name: 'D#sus2',
      frets: [-1, 6, 8, 8, 6, 6],
      fingers: [0, 1, 3, 4, 1, 1],
      barre: 6,
    ),
  ],
  'D#sus4': [
    ChordShape(
      name: 'D#sus4',
      frets: [-1, 6, 8, 8, 9, 6],
      fingers: [0, 1, 3, 4, 4, 1],
      barre: 6,
    ),
  ],
  'D#5': [
    ChordShape(
      name: 'D#5',
      frets: [-1, 6, 8, 8, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'D#9': [
    ChordShape(
      name: 'D#9',
      frets: [-1, 6, 5, 6, 6, 6],
      fingers: [0, 2, 1, 3, 3, 3],
      barre: 6,
    ),
  ],
  'D#m9': [
    ChordShape(
      name: 'D#m9',
      frets: [-1, 6, 4, 6, 6, -1],
      fingers: [0, 3, 1, 4, 4, 0],
      barre: 6,
    ),
  ],
  'D#/A#': [
    ChordShape(
      name: 'D#/A#',
      frets: [-1, 1, 1, 3, 4, 3],
      fingers: [0, 1, 1, 2, 4, 3],
      barre: 1,
    ),
  ],
  'D#7/A#': [
    ChordShape(
      name: 'D#7/A#',
      frets: [-1, 1, 1, 3, 2, 3],
      fingers: [0, 1, 1, 3, 2, 4],
      barre: 1,
    ),
  ],
  'D#add11': [
    ChordShape(
      name: 'D#add11',
      frets: [-1, 6, 6, 8, 8, 6],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 6,
    ),
  ],
  'Eb': [
    ChordShape(
      name: 'Eb',
      frets: [-1, 6, 8, 8, 8, 6],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 6,
    ),
    ChordShape(
      name: 'Eb',
      frets: [-1, -1, 5, 3, 4, 3],
      fingers: [0, 0, 3, 1, 2, 1],
    ),
  ],
  'Ebmaj7': [
    ChordShape(
      name: 'Ebmaj7',
      frets: [-1, 6, 8, 7, 8, 6],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 6,
    ),
  ],
  'D#maj7': [
    ChordShape(
      name: 'D#maj7',
      frets: [-1, 6, 8, 7, 8, 6],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 6,
    ),
  ],
  'Ebadd11': [
    ChordShape(
      name: 'Ebadd11',
      frets: [-1, 6, 6, 8, 8, 6],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 6,
    ),
  ],
  'E': [
    ChordShape(
      name: 'E',
      frets: [0, 2, 2, 1, 0, 0],
      fingers: [0, 2, 3, 1, 0, 0],
    ),
    ChordShape(
      name: 'E',
      frets: [-1, 7, 9, 9, 9, 7],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 7,
    ),
    ChordShape(
      name: 'E',
      frets: [0, 7, 6, 4, 5, 4],
      fingers: [0, 4, 3, 1, 2, 1],
      barre: 4,
    ),
  ],
  'Esus2': [
    ChordShape(
      name: 'Esus2',
      frets: [0, 2, 4, 4, 0, 0],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'E5': [
    ChordShape(
      name: 'E5',
      frets: [0, 2, 2, -1, -1, -1],
      fingers: [0, 1, 2, 0, 0, 0],
    ),
    ChordShape(
      name: 'E5',
      frets: [-1, 7, 9, 9, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'E9': [
    ChordShape(
      name: 'E9',
      frets: [0, 2, 0, 1, 0, 2],
      fingers: [0, 2, 0, 1, 0, 3],
    ),
  ],
  'Em9': [
    ChordShape(
      name: 'Em9',
      frets: [0, 2, 0, 0, 0, 2],
      fingers: [0, 1, 0, 0, 0, 2],
    ),
  ],
  'Esus4': [
    ChordShape(
      name: 'Esus4',
      frets: [0, 2, 2, 2, 0, 0],
      fingers: [0, 2, 3, 4, 0, 0],
    ),
  ],
  'Eadd11': [
    ChordShape(
      name: 'Eadd11',
      frets: [0, 0, 2, 1, 0, 0],
      fingers: [0, 0, 2, 1, 0, 0],
    ),
    ChordShape(
      name: 'Eadd11',
      frets: [0, 7, 9, 8, 10, 0],
      fingers: [0, 1, 3, 2, 4, 0],
    ),
  ],
  'F': [
    ChordShape(
      name: 'F',
      frets: [1, 3, 3, 2, 1, 1],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 1,
    ),
    ChordShape(
      name: 'F',
      frets: [-1, 8, 10, 10, 10, 8],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 8,
    ),
  ],
  'F6': [
    ChordShape(
      name: 'F6',
      frets: [-1, -1, 3, 2, 3, 1],
      fingers: [0, 0, 3, 2, 4, 1],
    ),
    ChordShape(
      name: 'F6',
      frets: [1, 3, 3, 2, 3, 1],
      fingers: [1, 3, 4, 2, 4, 1],
      barre: 1,
    ),
  ],
  'Fsus2': [
    ChordShape(
      name: 'Fsus2',
      frets: [1, 3, 3, 0, -1, -1],
      fingers: [1, 3, 4, 0, 0, 0],
    ),
    ChordShape(
      name: 'Fsus2',
      frets: [-1, 8, 10, 10, 8, 8],
      fingers: [0, 1, 3, 4, 1, 1],
      barre: 8,
    ),
  ],
  'F5': [
    ChordShape(
      name: 'F5',
      frets: [1, 3, 3, -1, -1, -1],
      fingers: [1, 3, 4, 0, 0, 0],
    ),
  ],
  'F9': [
    ChordShape(
      name: 'F9',
      frets: [1, 0, 1, 0, 1, -1],
      fingers: [1, 0, 2, 0, 3, 0],
    ),
  ],
  'Fm9': [
    ChordShape(
      name: 'Fm9',
      frets: [1, 3, 1, 1, 1, 3],
      fingers: [1, 3, 1, 1, 1, 4],
      barre: 1,
    ),
  ],
  'F/A': [
    ChordShape(
      name: 'F/A',
      frets: [-1, 0, 3, 2, 1, 1],
      fingers: [0, 0, 3, 2, 1, 1],
      barre: 1,
    ),
    ChordShape(
      name: 'F/A',
      frets: [5, 3, 3, 2, 1, 1],
      fingers: [4, 3, 3, 2, 1, 1],
      barre: 1,
    ),
  ],
  'Fsus4': [
    ChordShape(
      name: 'Fsus4',
      frets: [1, 3, 3, 3, 1, 1],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 1,
    ),
    ChordShape(
      name: 'Fsus4',
      frets: [-1, 8, 10, 10, 11, 8],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 8,
    ),
  ],
  'F7': [
    ChordShape(
      name: 'F7',
      frets: [1, 3, 1, 2, 1, 1],
      fingers: [1, 3, 1, 2, 1, 1],
      barre: 1,
    ),
  ],
  'Fadd11': [
    ChordShape(
      name: 'Fadd11',
      frets: [1, 1, 3, 2, 1, 1],
      fingers: [1, 1, 3, 2, 1, 1],
      barre: 1,
    ),
  ],
  'F#': [
    ChordShape(
      name: 'F#',
      frets: [2, 4, 4, 3, 2, 2],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 2,
    ),
  ],
  'F#sus2': [
    ChordShape(
      name: 'F#sus2',
      frets: [2, 4, 4, 2, 2, 4],
      fingers: [1, 3, 4, 1, 1, 2],
      barre: 2,
    ),
  ],
  'F#sus4': [
    ChordShape(
      name: 'F#sus4',
      frets: [2, 4, 4, 4, 2, 2],
      fingers: [1, 3, 4, 4, 1, 1],
      barre: 2,
    ),
  ],
  'F#5': [
    ChordShape(
      name: 'F#5',
      frets: [2, 4, 4, -1, -1, -1],
      fingers: [1, 3, 4, 0, 0, 0],
    ),
  ],
  'F#9': [
    ChordShape(
      name: 'F#9',
      frets: [-1, 9, 8, 9, 9, 9],
      fingers: [0, 2, 1, 3, 3, 3],
      barre: 9,
    ),
  ],
  'F#m9': [
    ChordShape(
      name: 'F#m9',
      frets: [2, 4, 2, 2, 2, 4],
      fingers: [1, 3, 1, 1, 1, 4],
      barre: 2,
    ),
  ],
  'F#add11': [
    ChordShape(
      name: 'F#add11',
      frets: [2, 4, 4, 3, 0, 2],
      fingers: [1, 3, 4, 2, 0, 1],
      barre: 2,
    ),
    ChordShape(
      name: 'F#add11',
      frets: [2, 4, 4, 3, 0, 0],
      fingers: [1, 3, 4, 2, 0, 0],
    ),
  ],
  'Gb': [
    ChordShape(
      name: 'Gb',
      frets: [2, 4, 4, 3, 2, 2],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 2,
    ),
  ],
  'Gbadd11': [
    ChordShape(
      name: 'Gbadd11',
      frets: [2, 4, 4, 3, 0, 2],
      fingers: [1, 3, 4, 2, 0, 1],
      barre: 2,
    ),
  ],
  'G': [
    ChordShape(
      name: 'G',
      frets: [3, 2, 0, 0, 0, 3],
      fingers: [3, 2, 0, 0, 0, 4],
    ),
    ChordShape(
      name: 'G',
      frets: [3, 5, 5, 4, 3, 3],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 3,
    ),
    ChordShape(
      name: 'G',
      frets: [-1, 10, 12, 12, 12, 10],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 10,
    ),
  ],
  'Gsus2': [
    ChordShape(
      name: 'Gsus2',
      frets: [3, 0, 0, 2, 3, 3],
      fingers: [2, 0, 0, 1, 3, 4],
    ),
  ],
  'G5': [
    ChordShape(
      name: 'G5',
      frets: [3, 5, 5, -1, -1, -1],
      fingers: [1, 3, 4, 0, 0, 0],
    ),
  ],
  'G9': [
    ChordShape(
      name: 'G9',
      frets: [3, 2, 3, 2, 0, -1],
      fingers: [2, 1, 3, 1, 0, 0],
    ),
  ],
  'Gm9': [
    ChordShape(
      name: 'Gm9',
      frets: [3, 5, 3, 3, 3, 5],
      fingers: [1, 3, 1, 1, 1, 4],
      barre: 3,
    ),
  ],
  'G/B': [
    ChordShape(
      name: 'G/B',
      frets: [-1, 2, 0, 0, 3, 3],
      fingers: [0, 1, 0, 0, 3, 4],
    ),
    ChordShape(
      name: 'G/B',
      frets: [7, 5, 5, 4, 3, 3],
      fingers: [4, 2, 3, 1, 1, 1],
      barre: 3,
    ),
  ],
  'Gsus4': [
    ChordShape(
      name: 'Gsus4',
      frets: [3, 3, 0, 0, 3, 3],
      fingers: [1, 1, 0, 0, 3, 4],
      barre: 3,
    ),
  ],
  'Gadd11': [
    ChordShape(
      name: 'Gadd11',
      frets: [3, 2, 0, 0, 1, 3],
      fingers: [3, 2, 0, 0, 1, 4],
    ),
    ChordShape(
      name: 'Gadd11',
      frets: [3, 3, 0, 0, 0, 3],
      fingers: [2, 3, 0, 0, 0, 4],
    ),
  ],
  'G#': [
    ChordShape(
      name: 'G#',
      frets: [4, 6, 6, 5, 4, 4],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 4,
    ),
  ],
  'G#/C': [
    ChordShape(
      name: 'G#/C',
      frets: [-1, 3, 1, 1, 1, -1],
      fingers: [0, 3, 1, 1, 1, 0],
      barre: 1,
    ),
  ],
  'G#add11': [
    ChordShape(
      name: 'G#add11',
      frets: [4, 4, 6, 5, 4, 4],
      fingers: [1, 1, 3, 2, 1, 1],
      barre: 4,
    ),
  ],
  'Ab': [
    ChordShape(
      name: 'Ab',
      frets: [4, 6, 6, 5, 4, 4],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 4,
    ),
  ],
  'Abadd11': [
    ChordShape(
      name: 'Abadd11',
      frets: [4, 4, 6, 5, 4, 4],
      fingers: [1, 1, 3, 2, 1, 1],
      barre: 4,
    ),
  ],
  'A': [
    ChordShape(
      name: 'A',
      frets: [-1, 0, 2, 2, 2, 0],
      fingers: [0, 0, 1, 2, 3, 0],
    ),
    ChordShape(
      name: 'A',
      frets: [5, 7, 7, 6, 5, 5],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 5,
    ),
    ChordShape(
      name: 'A',
      frets: [-1, 12, 14, 14, 14, 12],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 12,
    ),
  ],
  'Asus2': [
    ChordShape(
      name: 'Asus2',
      frets: [-1, 0, 2, 2, 0, 0],
      fingers: [0, 0, 1, 2, 0, 0],
    ),
  ],
  'Asus4': [
    ChordShape(
      name: 'Asus4',
      frets: [-1, 0, 2, 2, 3, 0],
      fingers: [0, 0, 1, 2, 3, 0],
    ),
  ],
  'A7sus4': [
    ChordShape(
      name: 'A7sus4',
      frets: [-1, 0, 2, 0, 3, 3],
      fingers: [0, 0, 1, 0, 3, 4],
    ),
    ChordShape(
      name: 'A7sus4',
      frets: [-1, 0, 2, 0, 3, 0],
      fingers: [0, 0, 1, 0, 2, 0],
    ),
  ],
  'A11': [
    ChordShape(
      name: 'A11',
      frets: [-1, 0, 0, 0, 0, 0],
      fingers: [0, 0, 0, 0, 0, 0],
    ),
    ChordShape(
      name: 'A11',
      frets: [-1, 0, 2, 0, 3, 3],
      fingers: [0, 0, 1, 0, 3, 4],
    ),
  ],
  'A9': [
    ChordShape(
      name: 'A9',
      frets: [-1, 0, 2, 4, 2, 3],
      fingers: [0, 0, 1, 3, 1, 2],
      barre: 2,
    ),
  ],
  'Bm11': [
    ChordShape(
      name: 'Bm11',
      frets: [7, 9, 7, 7, 7, 7],
      fingers: [1, 3, 1, 1, 1, 1],
      barre: 7,
    ),
    ChordShape(
      name: 'Bm11',
      frets: [-1, 2, 0, 2, 2, 0],
      fingers: [0, 1, 0, 2, 3, 0],
    ),
  ],
  'A6': [
    ChordShape(
      name: 'A6',
      frets: [-1, 0, 2, 2, 2, 2],
      fingers: [0, 0, 1, 1, 1, 1],
      barre: 2,
    ),
  ],
  'Aadd11': [
    ChordShape(
      name: 'Aadd11',
      frets: [-1, 0, 0, 2, 2, 0],
      fingers: [0, 0, 0, 1, 2, 0],
    ),
    ChordShape(
      name: 'Aadd11',
      frets: [5, 5, 7, 6, 5, 5],
      fingers: [1, 1, 3, 2, 1, 1],
      barre: 5,
    ),
  ],
  'A#': [
    ChordShape(
      name: 'A#',
      frets: [-1, 1, 3, 3, 3, 1],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 1,
    ),
  ],
  'A#add11': [
    ChordShape(
      name: 'A#add11',
      frets: [-1, 1, 1, 3, 3, 1],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 1,
    ),
  ],
  'A#m': [
    ChordShape(
      name: 'A#m',
      frets: [-1, 1, 3, 3, 2, 1],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 1,
    ),
  ],
  'Bb': [
    ChordShape(
      name: 'Bb',
      frets: [-1, 1, 3, 3, 3, 1],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 1,
    ),
    ChordShape(
      name: 'Bb',
      frets: [6, 8, 8, 7, 6, 6],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 6,
    ),
  ],
  'Bbadd11': [
    ChordShape(
      name: 'Bbadd11',
      frets: [-1, 1, 1, 3, 3, 1],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 1,
    ),
    ChordShape(
      name: 'Bbadd11',
      frets: [6, 6, 8, 7, 6, 6],
      fingers: [1, 1, 3, 2, 1, 1],
      barre: 6,
    ),
  ],
  'B': [
    ChordShape(
      name: 'B',
      frets: [-1, 2, 4, 4, 4, 2],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 2,
    ),
    ChordShape(
      name: 'B',
      frets: [7, 9, 9, 8, 7, 7],
      fingers: [1, 3, 4, 2, 1, 1],
      barre: 7,
    ),
  ],
  'B/F#': [
    ChordShape(
      name: 'B/F#',
      frets: [2, 2, 4, 4, 4, 2],
      fingers: [1, 1, 2, 3, 4, 1],
      barre: 2,
    ),
  ],
  'B/A#': [
    ChordShape(
      name: 'B/A#',
      frets: [-1, 1, 4, 4, 4, 2],
      fingers: [0, 1, 3, 3, 3, 1],
      barre: 1,
    ),
  ],
  'Bsus4': [
    ChordShape(
      name: 'Bsus4',
      frets: [-1, 2, 4, 4, 5, 2],
      fingers: [0, 1, 3, 4, 4, 1],
      barre: 2,
    ),
  ],
  'Badd11': [
    ChordShape(
      name: 'Badd11',
      frets: [-1, 2, 4, 4, 4, 0],
      fingers: [0, 1, 2, 3, 4, 0],
    ),
    ChordShape(
      name: 'Badd11',
      frets: [-1, 2, 2, 4, 4, 2],
      fingers: [0, 1, 1, 3, 4, 1],
      barre: 2,
    ),
    ChordShape(
      name: 'Badd11',
      frets: [7, 7, 9, 8, 7, 7],
      fingers: [1, 1, 3, 2, 1, 1],
      barre: 7,
    ),
  ],
  'B#': [
    ChordShape(
      name: 'B#',
      frets: [-1, 3, 2, 0, 1, 0],
      fingers: [0, 3, 2, 0, 1, 0],
    ),
  ],
  'Cm': [
    ChordShape(
      name: 'Cm',
      frets: [-1, 3, 5, 5, 4, 3],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 3,
    ),
  ],
  'C#m': [
    ChordShape(
      name: 'C#m',
      frets: [-1, 4, 6, 6, 5, 4],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 4,
    ),
  ],
  'C#mM7': [
    ChordShape(
      name: 'C#mM7',
      frets: [-1, 4, 6, 5, 5, 4],
      fingers: [0, 1, 4, 2, 3, 1],
      barre: 4,
    ),
  ],
  'C#m7': [
    ChordShape(
      name: 'C#m7',
      frets: [-1, 4, 6, 4, 5, 4],
      fingers: [0, 1, 3, 1, 2, 1],
      barre: 4,
    ),
  ],
  'C#m6': [
    ChordShape(
      name: 'C#m6',
      frets: [-1, 4, 2, 3, 2, -1],
      fingers: [0, 3, 1, 2, 1, 0],
      barre: 2,
    ),
  ],
  'C#m/B': [
    ChordShape(
      name: 'C#m/B',
      frets: [-1, 2, 2, 1, 2, 0],
      fingers: [0, 2, 3, 1, 4, 0],
    ),
  ],
  'Dm': [
    ChordShape(
      name: 'Dm',
      frets: [-1, -1, 0, 2, 3, 1],
      fingers: [0, 0, 0, 2, 3, 1],
    ),
  ],
  'D#m': [
    ChordShape(
      name: 'D#m',
      frets: [-1, 6, 8, 8, 7, 6],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 6,
    ),
  ],
  'Em': [
    ChordShape(
      name: 'Em',
      frets: [0, 2, 2, 0, 0, 0],
      fingers: [0, 2, 3, 0, 0, 0],
    ),
  ],
  'Em7': [
    ChordShape(
      name: 'Em7',
      frets: [0, 2, 0, 0, 0, 0],
      fingers: [0, 2, 0, 0, 0, 0],
    ),
  ],
  'Ebm': [
    ChordShape(
      name: 'Ebm',
      frets: [-1, 6, 8, 8, 7, 6],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 6,
    ),
  ],
  'F#m': [
    ChordShape(
      name: 'F#m',
      frets: [2, 4, 4, 2, 2, 2],
      fingers: [1, 3, 4, 1, 1, 1],
      barre: 2,
    ),
  ],
  'G#m': [
    ChordShape(
      name: 'G#m',
      frets: [4, 6, 6, 4, 4, 4],
      fingers: [1, 3, 4, 1, 1, 1],
      barre: 4,
    ),
  ],
  'Gm': [
    ChordShape(
      name: 'Gm',
      frets: [3, 5, 5, 3, 3, 3],
      fingers: [1, 3, 4, 1, 1, 1],
      barre: 3,
    ),
  ],
  'Bbm': [
    ChordShape(
      name: 'Bbm',
      frets: [-1, 1, 3, 3, 2, 1],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 1,
    ),
  ],
  'Am': [
    ChordShape(
      name: 'Am',
      frets: [-1, 0, 2, 2, 1, 0],
      fingers: [0, 0, 2, 3, 1, 0],
    ),
  ],
  'Am/G': [
    ChordShape(
      name: 'Am/G',
      frets: [3, 0, 2, 2, 1, 0],
      fingers: [4, 0, 2, 3, 1, 0],
    ),
  ],
  'Am/F#': [
    ChordShape(
      name: 'Am/F#',
      frets: [2, 0, 2, 2, 1, 0],
      fingers: [2, 0, 3, 4, 1, 0],
    ),
  ],
  'Am7': [
    ChordShape(
      name: 'Am7',
      frets: [-1, 0, 2, 0, 1, 0],
      fingers: [0, 0, 2, 0, 1, 0],
    ),
  ],
  'Am9': [
    ChordShape(
      name: 'Am9',
      frets: [-1, 0, 2, 0, 0, 0],
      fingers: [0, 0, 2, 0, 0, 0],
    ),
  ],
  'Bm': [
    ChordShape(
      name: 'Bm',
      frets: [-1, 2, 4, 4, 3, 2],
      fingers: [0, 1, 3, 4, 2, 1],
      barre: 2,
    ),
    ChordShape(
      name: 'Bm',
      frets: [7, 9, 9, 7, 7, 7],
      fingers: [1, 3, 4, 1, 1, 1],
      barre: 7,
    ),
  ],
  'C7': [
    ChordShape(
      name: 'C7',
      frets: [-1, 3, 2, 3, 1, 0],
      fingers: [0, 3, 2, 4, 1, 0],
    ),
  ],
  'D7': [
    ChordShape(
      name: 'D7',
      frets: [-1, -1, 0, 2, 1, 2],
      fingers: [0, 0, 0, 2, 1, 3],
    ),
  ],
  'E7': [
    ChordShape(
      name: 'E7',
      frets: [0, 2, 0, 1, 0, 0],
      fingers: [0, 2, 0, 1, 0, 0],
    ),
  ],
  'G7': [
    ChordShape(
      name: 'G7',
      frets: [3, 2, 0, 0, 0, 1],
      fingers: [3, 2, 0, 0, 0, 1],
    ),
  ],
  'A7': [
    ChordShape(
      name: 'A7',
      frets: [-1, 0, 2, 0, 2, 0],
      fingers: [0, 0, 1, 0, 2, 0],
    ),
  ],
  'A/C#': [
    ChordShape(
      name: 'A/C#',
      frets: [-1, 4, 2, 2, 2, -1],
      fingers: [0, 4, 1, 1, 1, 0],
      barre: 2,
    ),
    ChordShape(
      name: 'A/C#',
      frets: [-1, 4, 2, 2, 5, -1],
      fingers: [0, 2, 1, 1, 4, 0],
      barre: 2,
    ),
  ],
  'Bm/A': [
    ChordShape(
      name: 'Bm/A',
      frets: [-1, 0, 4, 4, 3, 2],
      fingers: [0, 0, 3, 4, 2, 1],
      barre: 2,
    ),
  ],
  'E7sus4': [
    ChordShape(
      name: 'E7sus4',
      frets: [0, 2, 0, 2, 0, 0],
      fingers: [0, 2, 0, 3, 0, 0],
    ),
  ],
  'Dm7': [
    ChordShape(
      name: 'Dm7',
      frets: [-1, -1, 0, 2, 1, 1],
      fingers: [0, 0, 0, 2, 1, 1],
      barre: 1,
    ),
  ],
  'Bbmaj7': [
    ChordShape(
      name: 'Bbmaj7',
      frets: [-1, 1, 3, 2, 3, 1],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 1,
    ),
  ],
  'Fm': [
    ChordShape(
      name: 'Fm',
      frets: [1, 3, 3, 1, 1, 1],
      fingers: [1, 3, 4, 1, 1, 1],
      barre: 1,
    ),
  ],

  // Major 7th (maj7) chords
  'Amaj7': [
    ChordShape(
      name: 'Amaj7',
      frets: [-1, 0, 2, 1, 2, 0],
      fingers: [0, 0, 2, 1, 3, 0],
    ),
  ],
  'Bmaj7': [
    ChordShape(
      name: 'Bmaj7',
      frets: [-1, 2, 4, 3, 4, 2],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 2,
    ),
  ],
  'Cmaj7': [
    ChordShape(
      name: 'Cmaj7',
      frets: [-1, 3, 2, 0, 0, 0],
      fingers: [0, 3, 2, 0, 0, 0],
    ),
  ],
  'Dmaj7': [
    ChordShape(
      name: 'Dmaj7',
      frets: [-1, -1, 0, 2, 2, 2],
      fingers: [0, 0, 0, 1, 1, 1],
      barre: 2,
    ),
  ],
  'Emaj7': [
    ChordShape(
      name: 'Emaj7',
      frets: [0, 2, 1, 1, 0, 0],
      fingers: [0, 2, 1, 1, 0, 0],
    ),
    ChordShape(
      name: 'Emaj7',
      frets: [-1, 7, 9, 8, 9, 7],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 7,
    ),
  ],
  'Fmaj7': [
    ChordShape(
      name: 'Fmaj7',
      frets: [-1, -1, 3, 2, 1, 0],
      fingers: [0, 0, 3, 2, 1, 0],
    ),
    ChordShape(
      name: 'Fmaj7',
      frets: [-1, 8, 10, 9, 10, 8],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 8,
    ),
  ],
  'Gmaj7': [
    ChordShape(
      name: 'Gmaj7',
      frets: [3, 2, 0, 0, 0, 2],
      fingers: [2, 1, 0, 0, 0, 3],
    ),
    ChordShape(
      name: 'Gmaj7',
      frets: [-1, 10, 12, 11, 12, 10],
      fingers: [0, 1, 3, 2, 4, 1],
      barre: 10,
    ),
  ],

  // 8 (octave/power chord) chords
  'A8': [
    ChordShape(
      name: 'A8',
      frets: [-1, 0, 2, 2, -1, -1],
      fingers: [0, 0, 1, 2, 0, 0],
    ),
  ],
  'B8': [
    ChordShape(
      name: 'B8',
      frets: [-1, 2, 4, 4, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'C8': [
    ChordShape(
      name: 'C8',
      frets: [-1, 3, 5, 5, -1, -1],
      fingers: [0, 1, 3, 4, 0, 0],
    ),
  ],
  'D8': [
    ChordShape(
      name: 'D8',
      frets: [-1, -1, 0, 2, 3, -1],
      fingers: [0, 0, 0, 1, 2, 0],
    ),
  ],
  'E8': [
    ChordShape(
      name: 'E8',
      frets: [0, 2, 2, -1, -1, -1],
      fingers: [0, 1, 2, 0, 0, 0],
    ),
  ],
  'F8': [
    ChordShape(
      name: 'F8',
      frets: [1, 3, 3, -1, -1, -1],
      fingers: [1, 3, 4, 0, 0, 0],
    ),
  ],
  'G8': [
    ChordShape(
      name: 'G8',
      frets: [3, 5, 5, -1, -1, -1],
      fingers: [1, 3, 4, 0, 0, 0],
    ),
  ],

  // 7th (dominant 7th) chords missing
  'B7': [
    ChordShape(
      name: 'B7',
      frets: [-1, 2, 1, 2, 0, 2],
      fingers: [0, 2, 1, 3, 0, 4],
    ),
  ],

  // Minor 7th (m7) chords missing
  'Bm7': [
    ChordShape(
      name: 'Bm7',
      frets: [-1, 2, 4, 2, 3, 2],
      fingers: [0, 1, 3, 1, 2, 1],
      barre: 2,
    ),
  ],
  'Cm7': [
    ChordShape(
      name: 'Cm7',
      frets: [-1, 3, 5, 3, 4, 3],
      fingers: [0, 1, 3, 1, 2, 1],
      barre: 3,
    ),
  ],
  'Fm7': [
    ChordShape(
      name: 'Fm7',
      frets: [1, 3, 1, 1, 1, 1],
      fingers: [1, 3, 1, 1, 1, 1],
      barre: 1,
    ),
  ],
  'Gm7': [
    ChordShape(
      name: 'Gm7',
      frets: [3, 5, 3, 3, 3, 3],
      fingers: [1, 3, 1, 1, 1, 1],
      barre: 3,
    ),
  ],
};

List<ChordShape> getChordShapes(String name) {
  if (name.isEmpty) return [];

  // Normalize Portuguese/Spanish notations before search
  var normalized = name;
  normalized = normalized.replaceAll('7M', 'maj7');

  // Replace '4' with 'sus4' (e.g. G4 -> Gsus4, E4 -> Esus4) only if not already preceded by 'sus'
  normalized = normalized.replaceAll(RegExp(r'(?<!sus)4(?![0-9])'), 'sus4');

  // Helper for lookup
  List<ChordShape>? lookup(String chordName) {
    if (chordShapes.containsKey(chordName)) return chordShapes[chordName];
    final rootMatch = RegExp(r'^[A-G][#b]?').firstMatch(chordName);
    if (rootMatch != null) {
      final root = rootMatch.group(0)!;
      final rest = chordName.substring(root.length);
      final enharmonicMap = {
        'A#': 'Bb',
        'Bb': 'A#',
        'C#': 'Db',
        'Db': 'C#',
        'D#': 'Eb',
        'Eb': 'D#',
        'F#': 'Gb',
        'Gb': 'F#',
        'G#': 'Ab',
        'Ab': 'G#',
      };
      if (enharmonicMap.containsKey(root)) {
        final altRoot = enharmonicMap[root]!;
        final altChord = altRoot + rest;
        if (chordShapes.containsKey(altChord)) return chordShapes[altChord];
      }
    }
    final lowerName = chordName.toLowerCase();
    for (final key in chordShapes.keys) {
      if (key.toLowerCase() == lowerName) {
        return chordShapes[key];
      }
    }
    return null;
  }

  // 1. Try exact/case-insensitive match of normalized name
  var shapes = lookup(normalized);
  if (shapes != null) return shapes;

  // 2. Try slash fallback (e.g. Am7/G -> Am7)
  if (normalized.contains('/')) {
    final baseName = normalized.split('/')[0].trim();
    if (baseName.isNotEmpty && baseName != normalized) {
      final baseShapes = getChordShapes(baseName);
      if (baseShapes.isNotEmpty) return baseShapes;
    }
  }

  // 3. Fallback to basic major/minor chord by simplifying the name
  final rootMatch = RegExp(r'^[A-G][#b]?').firstMatch(normalized);
  if (rootMatch != null) {
    final root = rootMatch.group(0)!;
    final rest = normalized.substring(root.length);

    // Determine if it is minor (contains 'm', 'dim', 'min' but not 'maj' or 'min7' etc.
    // Standard rule: if the remainder contains 'm' (minor), 'min', 'dim' and not 'maj'
    final isMinor =
        (rest.contains('m') || rest.contains('dim') || rest.contains('min')) &&
        !rest.contains('maj');
    final fallbackChord = isMinor ? '${root}m' : root;

    final fallbackShapes = lookup(fallbackChord);
    if (fallbackShapes != null) return fallbackShapes;
  }

  return [];
}

ChordShape? getChordShape(String name) {
  final shapes = getChordShapes(name);
  return shapes.isNotEmpty ? shapes.first : null;
}
