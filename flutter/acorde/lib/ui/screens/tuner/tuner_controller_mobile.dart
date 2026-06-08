import 'tuner_controller.dart';

class MobileTunerController implements TunerController {
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  void start({
    required void Function(double pitch) onPitch,
    required void Function(String error) onError,
  }) {
    _isListening = true;
    // On native, standard real-time pitch detection requires native code,
    // so we show the exact warning message from the React Native app.
    onError(
      "Native real-time detection requires specialized native modules. Web version is recommended for full accuracy.",
    );
  }

  @override
  void stop() {
    _isListening = false;
  }
}

TunerController createTunerController() => MobileTunerController();
