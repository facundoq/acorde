// Mocking some math for the test
const sampleRate = 44100;

// The algorithm extracted for testing
const autoCorrelate = (buffer: Float32Array, sampleRate: number) => {
  const SIZE = buffer.length;
  let rms = 0;
  for (let i = 0; i < SIZE; i++) rms += buffer[i] * buffer[i];
  rms = Math.sqrt(rms / SIZE);
  if (rms < 0.01) return -1;

  let r1 = 0, r2 = SIZE - 1, thres = 0.2;
  for (let i = 0; i < SIZE / 2; i++) { if (Math.abs(buffer[i]) < thres) { r1 = i; break; } }
  for (let i = 1; i < SIZE / 2; i++) { if (Math.abs(buffer[SIZE - i]) < thres) { r2 = SIZE - i; break; } }

  const subBuffer = buffer.slice(r1, r2);
  const subSize = subBuffer.length;
  const c = new Float32Array(subSize);
  for (let i = 0; i < subSize; i++) {
    for (let j = 0; j < subSize - i; j++) {
      c[i] = c[i] + subBuffer[j] * subBuffer[j + i];
    }
  }
  let d = 0;
  while (c[d] > c[d + 1]) d++;
  let maxval = -1, maxpos = -1;
  for (let i = d; i < subSize; i++) {
    if (c[i] > maxval) { maxval = c[i]; maxpos = i; }
  }
  
  let T0 = maxpos;
  
  // Parabolic interpolation for better accuracy
  const x1 = c[T0 - 1];
  const x2 = c[T0];
  const x3 = c[T0 + 1];
  const a = (x1 + x3 - 2 * x2) / 2;
  const b = (x3 - x1) / 2;
  if (a !== 0) {
    T0 = T0 - b / (2 * a);
  }

  return sampleRate / T0;
};

describe('Tuner Logic - Pitch Detection', () => {
  const generateSineWave = (freq: number, durationSeconds: number, sampleRate: number) => {
    const buffer = new Float32Array(2048);
    for (let i = 0; i < buffer.length; i++) {
      const t = i / sampleRate;
      // Fundamental frequency
      let signal = Math.sin(2 * Math.PI * freq * t);
      
      // Add 1st and 2nd harmonics (common in string instruments)
      signal += 0.5 * Math.sin(2 * Math.PI * (freq * 2) * t);
      signal += 0.25 * Math.sin(2 * Math.PI * (freq * 3) * t);
      
      // Add background noise (simulating a real room/mic)
      signal += (Math.random() * 2 - 1) * 0.05;
      
      buffer[i] = signal;
    }
    return buffer;
  };

  test('should correctly detect Guitar A2 (110Hz)', () => {
    const freq = 110.00;
    const buffer = generateSineWave(freq, 0.1, sampleRate);
    const detected = autoCorrelate(buffer, sampleRate);
    // Allow small margin of error for digital sampling
    expect(detected).toBeCloseTo(freq, 0);
  });

  test('should correctly detect Guitar E4 (329.63Hz)', () => {
    const freq = 329.63;
    const buffer = generateSineWave(freq, 0.1, sampleRate);
    const detected = autoCorrelate(buffer, sampleRate);
    expect(detected).toBeCloseTo(freq, 0);
  });

  test('should correctly detect Bass E1 (41.20Hz)', () => {
    const freq = 41.20;
    const buffer = generateSineWave(freq, 0.1, sampleRate);
    const detected = autoCorrelate(buffer, sampleRate);
    expect(detected).toBeCloseTo(freq, 0);
  });

  test('should return -1 for silent buffer', () => {
    const buffer = new Float32Array(2048).fill(0);
    const detected = autoCorrelate(buffer, sampleRate);
    expect(detected).toBe(-1);
  });
});
