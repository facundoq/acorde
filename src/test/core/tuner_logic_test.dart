import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:acorde/core/tuner_utils.dart';

void main() {
  const double sampleRate = 44100;

  Float32List generateSineWave(double freq, double sampleRate) {
    final buffer = Float32List(2048);
    final random = math.Random(42); // Seeded random for deterministic tests
    for (int i = 0; i < buffer.length; i++) {
      final t = i / sampleRate;
      // Fundamental frequency
      double signal = math.sin(2 * math.pi * freq * t);

      // Add 1st and 2nd harmonics
      signal += 0.5 * math.sin(2 * math.pi * (freq * 2) * t);
      signal += 0.25 * math.sin(2 * math.pi * (freq * 3) * t);

      // Add background noise (simulating room/mic)
      signal += (random.nextDouble() * 2 - 1) * 0.05;

      buffer[i] = signal;
    }
    return buffer;
  }

  group('Tuner Logic - Pitch Detection', () {
    test('should correctly detect Guitar A2 (110Hz)', () {
      final double freq = 110.00;
      final buffer = generateSineWave(freq, sampleRate);
      final detected = autoCorrelate(buffer, sampleRate);
      expect(detected, closeTo(freq, 1.5));
    });

    test('should correctly detect Guitar E4 (329.63Hz)', () {
      final double freq = 329.63;
      final buffer = generateSineWave(freq, sampleRate);
      final detected = autoCorrelate(buffer, sampleRate);
      expect(detected, closeTo(freq, 1.5));
    });

    test('should correctly detect Bass E1 (41.20Hz)', () {
      final double freq = 41.20;
      final buffer = generateSineWave(freq, sampleRate);
      final detected = autoCorrelate(buffer, sampleRate);
      expect(detected, closeTo(freq, 1.5));
    });

    test('should return -1 for silent buffer', () {
      final buffer = Float32List(2048); // defaults to 0.0
      final detected = autoCorrelate(buffer, sampleRate);
      expect(detected, equals(-1.0));
    });
  });
}
