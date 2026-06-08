import 'dart:math' as math;
import 'dart:typed_data';

double autoCorrelate(Float32List buffer, double sampleRate) {
  final int size = buffer.length;
  double rms = 0;

  for (int i = 0; i < size; i++) {
    rms += buffer[i] * buffer[i];
  }
  rms = math.sqrt(rms / size);
  if (rms < 0.01) return -1; // signal too weak

  int r1 = 0;
  int r2 = size - 1;
  double thres = 0.2;
  for (int i = 0; i < size ~/ 2; i++) {
    if (buffer[i].abs() < thres) {
      r1 = i;
      break;
    }
  }
  for (int i = 1; i < size ~/ 2; i++) {
    if (buffer[size - i].abs() < thres) {
      r2 = size - i;
      break;
    }
  }

  if (r2 <= r1) return -1;

  final subBuffer = buffer.sublist(r1, r2);
  final subSize = subBuffer.length;

  final c = Float32List(subSize);
  for (int i = 0; i < subSize; i++) {
    for (int j = 0; j < subSize - i; j++) {
      c[i] = c[i] + subBuffer[j] * subBuffer[j + i];
    }
  }

  int d = 0;
  while (d < subSize - 1 && c[d] > c[d + 1]) {
    d++;
  }
  double maxval = -1;
  int maxpos = -1;
  for (int i = d; i < subSize; i++) {
    if (c[i] > maxval) {
      maxval = c[i];
      maxpos = i;
    }
  }

  if (maxpos < 1 || maxpos >= subSize - 1) return -1;

  double t0 = maxpos.toDouble();

  final double x1 = c[maxpos - 1];
  final double x2 = c[maxpos];
  final double x3 = c[maxpos + 1];
  final double a = (x1 + x3 - 2 * x2) / 2;
  final double b = (x3 - x1) / 2;
  if (a != 0) {
    t0 = t0 - b / (2 * a);
  }

  return sampleRate / t0;
}
