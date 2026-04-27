// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:spa_app/config/app_config.dart';
// import 'package:spa_app/routes/app_router.dart';
// import 'handlers/background_handler.dart';
// import 'services/notification_app_service.dart';
// import 'services/fcm_service.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp();
//
//   FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
//
//   await NotificationAppService.init();
//   await FCMService.init();
//
//   runApp(const MyApp());
// }


import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/routes/app_router.dart';
import 'package:spa_app/services/realtime_service.dart';
import 'package:spa_app/storage/index.dart';

/// Background handler
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  appLog("📩 [BACKGROUND] messageId: ${message.messageId}");
  appLog("📦 [BACKGROUND] data: ${message.data}");
  appLog("🔔 [BACKGROUND] notification: ${message.notification?.title} - ${message.notification?.body}");

  // Hiển thị notification khi app ở background/killed
  await _showLocalNotification(message);
}

/// Local Notification setup
final FlutterLocalNotificationsPlugin localNoti = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
  'default_channel',
  'General Notifications',
  description: 'Default notification channel for the app',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('notification'),
);

/// Hàm hiển thị local notification
Future<void> _showLocalNotification(RemoteMessage message) async {
  try {
    final notification = message.notification;
    if (notification == null && message.data.isEmpty) {
      appLog("⚠️ No notification content");
      return;
    }

    String title = notification?.title ?? message.data['title'] ?? 'Thông báo mới';
    String body = notification?.body ?? message.data['body'] ?? message.data['content'] ?? 'Bạn có thông báo mới';
    String? orderId = message.data['orderId'];

    // Tạo ID duy nhất cho mỗi notification
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(1000000);

    // Tạo Android notification details
    AndroidNotificationDetails androidDetails = const AndroidNotificationDetails(
      // 'default_channel',
      'default_channel_v2',
      'General Notifications',
      channelDescription: 'Default notification channel for the app',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
      autoCancel: true,
    );

    // Tạo iOS notification details
    DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification.wav',
    );

    NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Tạo payload với tiền tố 'order_'
    String payload = orderId != null ? 'order_$orderId' : 'notification';

    await localNoti.show(
      notificationId,
      title,
      body,
      platformDetails,
      payload: payload,
    );

    // appLog("✅ Local notification shown: ID=$notificationId, Title=$title, Payload=$payload");
  } catch (e) {
    appLog("❌ Error showing local notification: $e");
  }
}

Future<void> _setupLocalNotifications() async {
  /// ANDROID
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  /// iOS settings
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNoti.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onNotificationTap,
    onDidReceiveBackgroundNotificationResponse: _onNotificationTapBackground,
  );

  /// Create Android channel
  await localNoti
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(defaultChannel);

  /// Request iOS permission
  await localNoti
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
    alert: true,
    badge: true,
    sound: true,
  );
}

/// Xử lý khi người dùng click vào notification khi app đang mở (foreground)
void _onNotificationTap(NotificationResponse response) {
  appLog("🔘 [FOREGROUND] Notification tapped: ${response.payload}");
  _handleNotificationTap(response.payload);
}

/// Xử lý khi người dùng click vào notification khi app ở background
void _onNotificationTapBackground(NotificationResponse response) {
  appLog("🔘 [BACKGROUND] Notification tapped: ${response.payload}");
  _handleNotificationTap(response.payload);
}

/// Hàm xử lý chung khi click notification
Future<void> _handleNotificationTap(String? payload) async {
  appLog("🚀 Handling notification tap with payload: $payload");

  final isLogin = await SharedPrefs.getValue(PrefType.bool, 'isLogin');
  final roleLogin = await SharedPrefs.getValue(PrefType.string, 'role');
  // appLog("🚀 [FOREGROUND] Processing message directly: type=$type, orderId=$orderId");
  if (isLogin == true && roleLogin?.replaceAll('"', '').trim() == 'ktv') {

    if (payload != null && payload.startsWith('order_')) {
      final orderId = payload.substring(6);
      appLog("🚀 Navigate to order from notification: $orderId");

      // Sử dụng WidgetsBinding để đảm bảo điều hướng sau khi build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          appRouter.go('/home-technician/orders/$orderId');
          appLog("✅ Navigation successful to order: $orderId");
        } catch (e) {
          appLog("❌ Navigation failed: $e");
          // Thử lại sau 1 giây
          Future.delayed(const Duration(seconds: 1), () {
            appRouter.go('/home-technician/orders/$orderId');
          });
        }
      });
    } else {
      appLog("⚠️ Invalid or missing payload: $payload");
    }
  }

}

/// Hàm xử lý trực tiếp khi nhận được message ở foreground (không cần click notification)
Future<void> _handleForegroundMessage(RemoteMessage message) async {
  final data = message.data;
  final type = data['type'];
  final orderId = data['orderId'];


  final isLogin = await SharedPrefs.getValue(PrefType.bool, 'isLogin');
  final roleLogin = await SharedPrefs.getValue(PrefType.string, 'role');
  // appLog("🚀 [FOREGROUND] Processing message directly: type=$type, orderId=$orderId");
  if (isLogin == true && roleLogin?.replaceAll('"', '').trim() == 'ktv') {

  // if (type == 'order' && orderId != null) {
    // Hiển thị dialog hỏi người dùng có muốn xem chi tiết không
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _showOrderDialog(orderId);
    // });
  }
}

/// Hiển thị dialog khi có đơn mới ở foreground
void _showOrderDialog(String orderId) {
  // Lấy context hiện tại - cần có cách lấy context phù hợp
  // Cách 1: Sử dụng navigatorKey
  final context = appRouter.routerDelegate.navigatorKey.currentContext;
  if (context == null) {
    appLog("⚠️ Cannot show dialog: no context available");
    // Fallback: điều hướng trực tiếp
    appRouter.go('/home-technician/orders/$orderId');
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Đơn hàng mới'),
        content: Text('Bạn có đơn hàng mới. Bạn có muốn xem chi tiết không?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Để sau'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Xem ngay'),
            onPressed: () {
              Navigator.of(context).pop();
              appRouter.go('/home-technician/orders/$orderId');
            },
          ),
        ],
      );
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // appLog("🚀 App starting...");

  await Firebase.initializeApp();
  // appLog("✅ Firebase initialized");

  // Đăng ký background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  // appLog("🎯 Background handler registered");

  await _setupLocalNotifications();
  // appLog("🔔 Local notifications initialized");

  /// Request permission
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  // appLog("🔐 Permission status: ${settings.authorizationStatus}");

  /// Lấy FCM token
  final token = await FirebaseMessaging.instance.getToken();
  appLog("📱 FCM Token: $token");

  /// Realtime service
  final realtimeService = RealtimeService();
  try {
    realtimeService.connect();
    appLog("🔌 Realtime connected");
  } catch (e) {
    appLog("❌ Realtime connection failed: $e");
  }

  // *** XỬ LÝ KHI APP ĐANG MỞ (FOREGROUND) ***
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    // appLog("📩 [FOREGROUND] message received");
    // appLog("📦 [FOREGROUND] data: $data");
    // appLog("🔔 [FOREGROUND] notification: ${notification?.title} - ${notification?.body}");
    // appLog("🔔 [FOREGROUND] orderId: ${data['orderId']}");

    // Hiển thị local notification (để người dùng thấy)
    await _showLocalNotification(message);

    // 🔥 QUAN TRỌNG: Xử lý trực tiếp message khi app đang mở
    // Không cần chờ người dùng click notification
    _handleForegroundMessage(message);
  });

  /// Click notification khi app đang ở background (do FCM gửi trực tiếp)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    final data = message.data;
    final type = data['type'];
    final orderId = data['orderId'];

    appLog("🔘 [FCM - OPENED] Notification clicked from background");
    appLog("📦 Data: $data");

    final isLogin = await SharedPrefs.getValue(PrefType.bool, 'isLogin');
    final roleLogin = await SharedPrefs.getValue(PrefType.string, 'role');
    // appLog("🚀 [FOREGROUND] Processing message directly: type=$type, orderId=$orderId");
    if (isLogin == true && roleLogin?.replaceAll('"', '').trim() == 'ktv') {
      if (type == 'order' && orderId != null) {
        appLog("🚀 Navigate to order from FCM: $orderId");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appRouter.go('/home-technician/orders/$orderId');
        });
      } else {
        appLog("⚠️ Invalid navigation data from FCM");
      }
    } else {
      appLog("$isLogin - $roleLogin");
    }

  });

  /// App killed -> open from notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    appLog("💀 [KILLED -> OPEN] messageId: ${initialMessage.messageId}");
    appLog("📦 data: ${initialMessage.data}");

    final data = initialMessage.data;
    final type = data['type'];
    final orderId = data['orderId'];

    if (type == 'order' && orderId != null) {
      appLog("🚀 Navigate (delayed) to order: $orderId");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.go('/home-technician/orders/$orderId');
      });
    }
  } else {
    // appLog("ℹ️ No initial message");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}