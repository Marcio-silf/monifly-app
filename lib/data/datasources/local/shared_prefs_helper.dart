import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  SharedPrefsHelper._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs {
    if (_prefs == null)
      throw Exception('SharedPrefs not initialized. Call init() first.');
    return _prefs!;
  }

  // Booleans
  static Future<bool> setBool(String key, bool value) =>
      prefs.setBool(key, value);
  static bool getBool(String key, {bool defaultValue = false}) =>
      prefs.getBool(key) ?? defaultValue;

  // Strings
  static Future<bool> setString(String key, String value) =>
      prefs.setString(key, value);
  static String? getString(String key) => prefs.getString(key);

  // Doubles
  static Future<bool> setDouble(String key, double value) =>
      prefs.setDouble(key, value);
  static double getDouble(String key, {double defaultValue = 0.0}) =>
      prefs.getDouble(key) ?? defaultValue;

  // Integers
  static Future<bool> setInt(String key, int value) => prefs.setInt(key, value);
  static int getInt(String key, {int defaultValue = 0}) =>
      prefs.getInt(key) ?? defaultValue;

  // Remove
  static Future<bool> remove(String key) => prefs.remove(key);

  // Clear all
  static Future<bool> clear() => prefs.clear();
}

