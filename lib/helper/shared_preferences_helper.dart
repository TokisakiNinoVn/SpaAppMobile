// file: lib/helper/format_helper.dart
// import '../../../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckLoginHelper {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogin = prefs.getBool('isLogin') ?? false;
    return isLogin;
  }

  static Future<bool> isLoggedInBool() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLogin') ?? false;
  }
}
