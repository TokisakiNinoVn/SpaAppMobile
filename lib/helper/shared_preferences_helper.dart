// file: lib/helper/format_helper.dart
// import '../../../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/helper/logger_utils.dart';

class SharedPreferencesHelper {
  static Future<bool> listAllKeyValue() async {
    try {

      final trace = StackTrace.current.toString().split('\n');

      print('====================================[ SharedPreferencesHelper.listAllKeyValue ]==========================================');
      // Dòng [1] thường là nơi gọi trực tiếp
      if (trace.length > 1) {
        final traceLine = StackTrace.current.toString().split('\n')[1];

        final regex = RegExp(r'#\d+\s+(.+)\s+\((.+)\)');
        final match = regex.firstMatch(traceLine);

        if (match != null) {
          final method = match.group(1);
          final location = match.group(2);

          print('$location -> $method');
        } else {
          print(traceLine);
        }
      }

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
      print('==============================================[ End ]======================================================');
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