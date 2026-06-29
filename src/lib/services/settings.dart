import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _settingsKey = 'acorde_font_size';
  static const int defaultFontSize = 12;

  static Future<int> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_settingsKey) ?? defaultFontSize;
  }

  static Future<void> saveFontSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_settingsKey, size);
  }

  static const String _sourcesConfigKey = 'acorde_sources_config';

  static Future<Map<String, bool>> getSourcesConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_sourcesConfigKey);
    if (list != null) {
      final Map<String, bool> config = {};
      for (final item in list) {
        final parts = item.split(':');
        if (parts.length == 2) {
          config[parts[0]] = parts[1] == 'true';
        }
      }
      // Ensure all keys exist in case they are missing
      final defaults = _defaultSourcesConfig();
      defaults.forEach((key, value) {
        config.putIfAbsent(key, () => value);
      });
      return config;
    }
    return _defaultSourcesConfig();
  }

  static Future<void> saveSourcesConfig(Map<String, bool> config) async {
    final prefs = await SharedPreferences.getInstance();
    final list = config.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_sourcesConfigKey, list);
  }

  static const String _googleApiKey = 'google_api_key';
  static const String _googleCx = 'google_cx';

  static Future<String?> getGoogleApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleApiKey);
  }

  static Future<void> saveGoogleApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleApiKey, key);
  }

  static Future<String?> getGoogleCx() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_googleCx);
  }

  static Future<void> saveGoogleCx(String cx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_googleCx, cx);
  }

  static Map<String, bool> _defaultSourcesConfig() {
    return {
      'ultimateguitar': true,
      'cifraclub': false,
      'lacuerda': false,
      'cifras': false,
    };
  }
}
