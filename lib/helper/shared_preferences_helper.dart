// file: lib/helper/format_helper.dart
// import '../../../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static Future<bool> listAllKeyValue() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keys = prefs.getKeys();

      if (keys.isEmpty) {
        print("No data found in SharedPreferences.");
        return true;
      }

      for (final key in keys) {
        final value = prefs.get(key);
        print("Key: $key | Value: $value | Type: ${value.runtimeType}");
      }

      return true;
    } catch (e) {
      print("Error while listing SharedPreferences: $e");
      return false;
    }
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('isLogin', false);
  }
}