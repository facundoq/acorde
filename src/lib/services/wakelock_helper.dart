import 'package:flutter/services.dart';

class WakelockHelper {
  static const _channel = MethodChannel('com.example.acorde/wakelock');

  static Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (_) {
      // Ignored (e.g. during widget tests or unsupported platforms)
    }
  }

  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (_) {
      // Ignored (e.g. during widget tests or unsupported platforms)
    }
  }
}
