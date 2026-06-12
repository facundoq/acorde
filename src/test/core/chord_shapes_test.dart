import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/chord_shapes.dart';

void main() {
  group('Chord Shapes Tests', () {
    test('should contain shapes for C chord', () {
      final cShapes = chordShapes['C'];
      expect(cShapes, isNotNull);
      expect(cShapes!.length, equals(3));
      expect(cShapes[0].name, equals('C'));
      expect(cShapes[0].frets, equals([-1, 3, 2, 0, 1, 0]));
    });

    test('should contain shapes for D chord', () {
      final dShapes = chordShapes['D'];
      expect(dShapes, isNotNull);
      expect(dShapes!.length, equals(3));
      expect(dShapes[0].name, equals('D'));
      expect(dShapes[0].frets, equals([-1, -1, 0, 2, 3, 2]));
    });

    test('getChordShapes should look up chords case-insensitively', () {
      final cShapes = getChordShapes('c');
      expect(cShapes.length, equals(3));
      expect(cShapes[0].name, equals('C'));

      final nonExistent = getChordShapes('XYZ');
      expect(nonExistent, isEmpty);
    });

    test('getChordShape should return the first shape', () {
      final cShape = getChordShape('c');
      expect(cShape, isNotNull);
      expect(cShape!.name, equals('C'));
    });

    test('should contain new maj7, 8, and m7 chord shapes', () {
      final amaj7 = getChordShape('Amaj7');
      expect(amaj7, isNotNull);
      expect(amaj7!.name, equals('Amaj7'));
      expect(amaj7.frets, equals([-1, 0, 2, 1, 2, 0]));

      final f8 = getChordShape('F8');
      expect(f8, isNotNull);
      expect(f8!.name, equals('F8'));
      expect(f8.frets, equals([1, 3, 3, -1, -1, -1]));

      final b7 = getChordShape('B7');
      expect(b7, isNotNull);
      expect(b7!.name, equals('B7'));

      final gm7 = getChordShape('Gm7');
      expect(gm7, isNotNull);
      expect(gm7!.name, equals('Gm7'));
    });

    test('should contain add11 chord shapes', () {
      final badd11 = getChordShape('Badd11');
      expect(badd11, isNotNull);
      expect(badd11!.name, equals('Badd11'));
      expect(badd11.frets, equals([-1, 2, 4, 4, 4, 0]));

      final aadd11 = getChordShape('Aadd11');
      expect(aadd11, isNotNull);
      expect(aadd11!.name, equals('Aadd11'));
      expect(aadd11.frets, equals([-1, 0, 0, 2, 2, 0]));

      final cadd11 = getChordShape('Cadd11');
      expect(cadd11, isNotNull);
      expect(cadd11!.name, equals('Cadd11'));
      expect(cadd11.frets, equals([-1, 3, 3, 0, 1, 0]));
    });
  });
}
