import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:spa_app/services/notification_app_service.dart';
import 'package:spa_app/handlers/notification_handler.dart';
import 'package:spa_app/helper/logger_utils.dart';

class FCMService {
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    final token = await messaging.getToken();
    appLog("📱 FCM Token: $token");

    FirebaseMessaging.onMessage.listen((message) async {
      await NotificationAppService.showLocalNotification(message);
      NotificationHandler.handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final orderId = message.data['orderId'];

      if (orderId != null) {
        NotificationHandler.handleTap('order_$orderId');
      }
    });
  }
}
