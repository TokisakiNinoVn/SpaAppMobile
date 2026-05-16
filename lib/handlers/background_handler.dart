import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:spa_app/services/notification_app_service.dart';
import 'package:spa_app/helper/logger_utils.dart';

Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  appLog("📦 [BACKGROUND] data: ${message.data}");
  await NotificationAppService.showLocalNotification(message);
}
