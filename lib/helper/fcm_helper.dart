// file: lib/helper/fcm_helper.dart

import 'dart:async';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logger_utils.dart';

class FcmHelper {
  static String? _fcmToken;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Lấy FCM token
  static Future<String?> getFCMToken() async {
    try {
      final isSupported = await FirebaseMessaging.instance.isSupported();

      if (!isSupported) {
        appLog('FCM không được hỗ trợ trên thiết bị này');
        return null;
      }

      /// Request permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        appLog('User từ chối notification permission');
        return null;
      }

      /// Firebase Installation ID
      final installationId = await FirebaseInstallations.instance.getId();
      appLog('Firebase Installation ID: $installationId');

      /// Get token
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        _fcmToken = token;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);

        appLog('FCM Token: $token');
      }

      /// Listen token refresh (chỉ listen 1 lần)
      _tokenRefreshSubscription ??=
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
            _fcmToken = newToken;

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('fcm_token', newToken);

            appLog('FCM Token refreshed: $newToken');
          });

      return _fcmToken;
    } catch (e, stackTrace) {
      appLog('Lỗi lấy FCM token: $e');
      appLog(stackTrace.toString());

      return null;
    }
  }

  /// Lấy token cache
  static Future<String?> getSavedToken() async {
    if (_fcmToken != null) return _fcmToken;

    final prefs = await SharedPreferences.getInstance();

    _fcmToken = prefs.getString('fcm_token');

    return _fcmToken;
  }

  /// Dispose listener nếu cần
  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}