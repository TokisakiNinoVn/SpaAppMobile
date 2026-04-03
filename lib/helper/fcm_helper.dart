// file: lib/helper/fcm_helper.dart
// import '../../../config/app_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FcmHelper {
  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;

    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('fcm_token');

    if (_token == null) {
      _token = await FirebaseMessaging.instance.getToken();
      if (_token != null) {
        await prefs.setString('fcm_token', _token!);
      }
    }

    return _token;
  }
}