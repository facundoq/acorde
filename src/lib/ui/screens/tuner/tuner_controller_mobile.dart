import 'dart:async';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/tuner_utils.dart';
import 'tuner_controller.dart';

class MobileTunerController implements TunerController {
  bool _isListening = false;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _subscription;

  // The AudioRecorder uses 16000 Hz PCM-16 for universal compatibility and low CPU usage.
  static const int _sampleRate = 16000;

  @override
  bool get isListening => _isListening;

  @override
  void start({
    required void Function(double pitch) onPitch,
    required void Function(String error) onError,
  }) async {
    if (_isListening) return;

    // Request microphone permission at runtime.
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      onError(
        'Microphone permission was denied. Please enable it in Settings to use the tuner.',
      );
      return;
    }

    _recorder = AudioRecorder();

    final isSupported = await _recorder!.hasPermission();
    if (!isSupported) {
      onError('Microphone is not available on this device.');
      return;
    }

    final isPcmSupported = await _recorder!.isEncoderSupported(AudioEncoder.pcm16bits);
    if (!isPcmSupported) {
      onError('PCM 16-bit audio recording is not supported on this device.');
      return;
    }

    try {
      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      _isListening = true;

      // Accumulate bytes into a buffer big enough for autoCorrelate (2048 samples).
      // Each PCM-16 sample is 2 bytes.
      const int frameSize = 2048;
      const int bytesNeeded = frameSize * 2; // 2 bytes per int16 sample
      final List<int> byteAccumulator = [];

      _subscription = stream.listen(
        (Uint8List chunk) {
          byteAccumulator.addAll(chunk);

          while (byteAccumulator.length >= bytesNeeded) {
            // Extract one frame worth of bytes.
            final frameBytes = byteAccumulator.sublist(0, bytesNeeded);
            byteAccumulator.removeRange(0, bytesNeeded);

            // Convert Int16 PCM bytes to Float32 normalised in [-1, 1].
            final floatBuffer = Float32List(frameSize);
            for (int i = 0; i < frameSize; i++) {
              final int lo = frameBytes[i * 2];
              final int hi = frameBytes[i * 2 + 1];
              // Little-endian signed int16.
              int sample = (hi << 8) | lo;
              if (sample >= 0x8000) sample -= 0x10000;
              floatBuffer[i] = sample / 32768.0;
            }

            final detected = autoCorrelate(floatBuffer, _sampleRate.toDouble());
            if (detected != -1) {
              onPitch(detected);
            }
          }
        },
        onError: (e) {
          onError('Audio stream error: $e');
          stop();
        },
      );
    } catch (e) {
      onError('Could not start microphone: $e');
      _isListening = false;
      await _recorder?.dispose();
      _recorder = null;
    }
  }

  @override
  void stop() {
    _isListening = false;
    _subscription?.cancel();
    _subscription = null;
    _recorder
        ?.stop()
        .then((_) {
          _recorder?.dispose();
          _recorder = null;
        })
        .catchError((_) {
          _recorder = null;
        });
  }
}

TunerController createTunerController() => MobileTunerController();
