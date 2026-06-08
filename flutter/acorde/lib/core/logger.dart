// ignore_for_file: avoid_print
typedef LogCallback = void Function(String msg);

class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  final List<LogCallback> _callbacks = [];

  void Function() subscribe(LogCallback callback) {
    _callbacks.add(callback);
    return () {
      _callbacks.remove(callback);
    };
  }

  void log(String msg) {
    print(msg);
    // Avoid mutating list during iteration
    for (final callback in List<LogCallback>.from(_callbacks)) {
      callback(msg);
    }
  }

  void warn(String msg) {
    print('WARN: $msg');
    for (final callback in List<LogCallback>.from(_callbacks)) {
      callback('WARN: $msg');
    }
  }

  void error(String msg) {
    print('ERROR: $msg');
    for (final callback in List<LogCallback>.from(_callbacks)) {
      callback('ERROR: $msg');
    }
  }
}

final logger = Logger();
