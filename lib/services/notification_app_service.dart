import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:spa_app/handlers/notification_handler.dart';
import 'package:spa_app/helper/logger_utils.dart';

class NotificationAppService {
  static final FlutterLocalNotificationsPlugin _noti =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel =
  AndroidNotificationChannel(
    'default_channel',
    'General Notifications',
    description: 'Default notification channel',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('notification'),
  );

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _noti.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onTapBackground,
    );

    await _noti
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;

      String title =
          notification?.title ?? message.data['title'] ?? 'Thông báo';
      String body =
          notification?.body ?? message.data['body'] ?? 'Bạn có thông báo mới';

      int id = DateTime.now().millisecondsSinceEpoch % 100000;

      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'General Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails();

      await _noti.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
      );
    } catch (e) {
      appLog("❌ show notification error: $e");
    }
  }

  static void _onTap(NotificationResponse response) {
    NotificationHandler.handleTap(response.payload);
  }

  static void _onTapBackground(NotificationResponse response) {
    NotificationHandler.handleTap(response.payload);
  }
}
