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
  });
}
