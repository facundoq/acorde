import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:acorde/services/settings.dart';

void main() {
  group('SettingsService Tests', () {
    setUp(() {
      // Mock initial values for SharedPreferences
      SharedPreferences.setMockInitialValues({});
    });

    test('should get default font size', () async {
      final size = await SettingsService.getFontSize();
      expect(size, equals(12));
    });

    test('should save and get font size', () async {
      await SettingsService.saveFontSize(18);
      final size = await SettingsService.getFontSize();
      expect(size, equals(18));
    });

    test('should get default sources config', () async {
      final config = await SettingsService.getSourcesConfig();
      expect(config['ultimateguitar'], isTrue);
      expect(config['cifraclub'], isFalse);
      expect(config['lacuerda'], isFalse);
      expect(config['cifras'], isFalse);
    });

    test('should save and get custom sources config', () async {
      final newConfig = {
        'ultimateguitar': false,
        'cifraclub': true,
        'lacuerda': true,
        'cifras': false,
      };
      await SettingsService.saveSourcesConfig(newConfig);
      final config = await SettingsService.getSourcesConfig();
      expect(config['ultimateguitar'], isFalse);
      expect(config['cifraclub'], isTrue);
      expect(config['lacuerda'], isTrue);
      expect(config['cifras'], isFalse);
    });
  });
}
