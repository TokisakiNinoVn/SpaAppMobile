import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spa_app/routes/app_router.dart';
import 'package:spa_app/services/realtime_service.dart';

/// Background handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background message: ${message.messageId}");
}

/// Local Notification setup
final FlutterLocalNotificationsPlugin localNoti =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
  'default_channel',
  'General Notifications',
  description: 'Default notification channel for the app',
  importance: Importance.max,
);

Future<void> _setupLocalNotifications() async {
  /// ANDROID
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  /// 🔥 FIX IOS (QUAN TRỌNG)
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNoti.initialize(initSettings);

  /// Create Android channel
  await localNoti
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(defaultChannel);

  /// Request iOS permission
  await localNoti
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 FIX: dùng init đơn giản (không firebase_options.dart)
  await Firebase.initializeApp();

  /// Background message
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  /// Local notifications
  await _setupLocalNotifications();

  /// Request FCM permission (iOS)
  await FirebaseMessaging.instance.requestPermission();

  /// Realtime service (có thể fail nếu chưa login, nhưng không crash)
  final realtimeService = RealtimeService();
  realtimeService.connect();

  /// Foreground message
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final noti = message.notification;
    final android = noti?.android;

    if (noti != null && android != null) {
      await localNoti.show(
        noti.hashCode,
        noti.title,
        noti.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            defaultChannel.id,
            defaultChannel.name,
            channelDescription: defaultChannel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  /// Click notification (background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final orderId = data['orderId'];

    if (type == 'order' && orderId != null) {
      appRouter.go('/home-technician/orders/$orderId');
    }
  });

  /// App killed -> open from notification
  final initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    final data = initialMessage.data;
    final type = data['type'];
    final orderId = data['orderId'];

    if (type == 'order' && orderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.go('/home-technician/orders/$orderId');
      });
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Spa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
