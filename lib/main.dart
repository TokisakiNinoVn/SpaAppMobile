import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spa_app/routes/app_router.dart';
import 'package:spa_app/services/realtime_service.dart';
import 'package:go_router/go_router.dart';

/// ------------------------------------------------------------
/// Background handler (bắt buộc phải nằm ngoài main)
/// ------------------------------------------------------------
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background message: ${message.messageId}");
}

/// ------------------------------------------------------------
/// Local Notification setup
/// ------------------------------------------------------------
final FlutterLocalNotificationsPlugin localNoti =
FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
  'default_channel',
  'General Notifications',
  description: 'Default notification channel for the app',
  importance: Importance.max,
);

Future<void> _setupLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await localNoti.initialize(initSettings);

  await localNoti
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(defaultChannel);
}

/// ------------------------------------------------------------
/// Main
/// ------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Realtime service
  final realtimeService = RealtimeService();
  realtimeService.connect();

  // Background message listener
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Local notification setup
  await _setupLocalNotifications();

  /// ----------------------------------------------------------
  /// Foreground FCM listener
  /// ----------------------------------------------------------
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint("🔥 RAW MESSAGE:");
    debugPrint(message.toMap().toString());

    debugPrint("📦 DATA: ${message.data}");
    debugPrint("🔔 NOTIFICATION: ${message.notification?.toMap()}");

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

  /// ----------------------------------------------------------
  /// Khi user bấm vào notification (app background)
  /// ----------------------------------------------------------
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final data = message.data;
    debugPrint("🚪 Notification click DATA: $data");

    final type = data['type'];
    final orderId = data['orderId'];

    if (type == 'order' && orderId != null) {
      appRouter.go('/home-technician/orders/$orderId');
    } else {
      print("🥲 Lỗi gì đó chăng không?");
    }
  });

  /// ----------------------------------------------------------
  /// Khi app bị kill hoàn toàn và mở từ notification
  /// ----------------------------------------------------------
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

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
