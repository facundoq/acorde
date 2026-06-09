// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';
import '../../../core/tuner_utils.dart';
import 'tuner_controller.dart';

class WebTunerController implements TunerController {
  dynamic _audioCtx;
  dynamic _analyser;
  dynamic _microphone;
  html.MediaStream? _stream;
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  void start({
    required void Function(double pitch) onPitch,
    required void Function(String error) onError,
  }) async {
    if (_isListening) return;

    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        onError(
          "Microphone access is not supported by your browser or requires a secure (HTTPS) connection.",
        );
        return;
      }

      _stream = await mediaDevices.getUserMedia({'audio': true});

      final jsAudioContext =
          js.context['AudioContext'] ?? js.context['webkitAudioContext'];
      if (jsAudioContext == null) {
        onError("Web Audio API is not supported by this browser.");
        return;
      }

      final ctx = js.JsObject(jsAudioContext);
      _audioCtx = ctx;

      final analyserNode = ctx.callMethod('createAnalyser');
      analyserNode['fftSize'] = 2048;
      _analyser = analyserNode;

      _microphone = ctx.callMethod('createMediaStreamSource', [_stream]);
      _microphone.callMethod('connect', [analyserNode]);

      _isListening = true;
      _runLoop(onPitch);
    } catch (e) {
      onError("Microphone access denied or not available.");
    }
  }

  void _runLoop(void Function(double pitch) onPitch) {
    if (!_isListening || _analyser == null || _audioCtx == null) return;

    final int fftSize = _analyser['fftSize'] as int;
    final buffer = Float32List(fftSize);
    final double sampleRate = (_audioCtx['sampleRate'] as num).toDouble();

    void update() {
      if (!_isListening || _analyser == null || _audioCtx == null) return;

      _analyser.callMethod('getFloatTimeDomainData', [buffer]);

      final detectedPitch = autoCorrelate(buffer, sampleRate);
      if (detectedPitch != -1) {
        onPitch(detectedPitch);
      }

      html.window.requestAnimationFrame((time) {
        update();
      });
    }

    update();
  }

  @override
  void stop() {
    _isListening = false;
    try {
      _microphone?.callMethod('disconnect');
      _audioCtx?.callMethod('close');
      _stream?.getTracks().forEach((track) {
        try {
          track.stop();
        } catch (_) {}
      });
    } catch (_) {}
    _microphone = null;
    _audioCtx = null;
    _analyser = null;
    _stream = null;
  }
}

TunerController createTunerController() => WebTunerController();
