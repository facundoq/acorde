import 'tuner_controller_stub.dart'
    if (dart.library.html) 'tuner_controller_web.dart'
    if (dart.library.io) 'tuner_controller_mobile.dart';

abstract class TunerController {
  factory TunerController() => createTunerController();

  bool get isListening;

  void start({
    required void Function(double pitch) onPitch,
    required void Function(String error) onError,
  });

  void stop();
}
