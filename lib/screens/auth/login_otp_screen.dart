import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:flutter/foundation.dart';

import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/services/auth_service.dart';
import '../../../helper/snackbar_helper.dart';

class LoginOTPScreen extends StatefulWidget {
  @override
  _LoginOTPScreen createState() => _LoginOTPScreen();
}

class _LoginOTPScreen extends State<LoginOTPScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  String? _fcmToken;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'otp_channel',
    'OTP Notifications',
    description: 'Kênh thông báo mã OTP',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getFCMToken();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _animController.forward();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    appLog('iOS foreground notification: $title | $body | payload: $payload');
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    appLog('Notification tapped, payload: $payload');
    if (payload != null && payload.isNotEmpty && mounted) {
      // context.go('${GlobalRouterConfig.confirmLoginOTP}/$payload');
    }
  }

  Future<void> _showOTPNotification({
    required String phone,
    String? lastOTP,
  }) async {
    final String body = lastOTP != null
        ? 'Mã OTP của bạn là: $lastOTP'
        : 'Mã OTP đã được gửi đến số $phone';

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      channelDescription: 'Kênh thông báo mã OTP',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'OTP',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      'Mã OTP',
      body,
      details,
      payload: phone,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        appLog('User từ chối permission notification');
        SnackBarHelper.showError(context, 'Bạn cần cho phép thông báo để nhận mã OTP. Vui lòng bật quyền thông báo trong cài đặt.');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          appLog('APNs token null — chạy trên simulator hoặc chưa config APNs');
          SnackBarHelper.showError(context, 'Không thể lấy APNs token. Vui lòng chạy trên thiết bị thật và đảm bảo đã cấu hình APNs đúng cách.');
          return;
        }
        appLog('APNs token: $apnsToken');
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        setState(() => _fcmToken = token);
        appLog('FCM token: $token');
      } else {
        SnackBarHelper.showError(context, 'Không thể lấy FCM token. Vui lòng thử lại hoặc kiểm tra cấu hình Firebase.');
        appLog('FCM token null sau khi đã có APNs token');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _updateFCMTokenIfLoggedIn(newToken);
      });
    } catch (e) {
      appLog('Lỗi lấy FCM token: $e');
    }
  }

  Future<void> _updateFCMTokenIfLoggedIn(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        // await authService.updateFCMToken(newToken);
      } catch (e) {
        debugPrint('Lỗi cập nhật FCM token khi refresh: $e');
      }
    }
  }

  void startCountdown() {
    setState(() {
      _countdown = 60;
      _isButtonDisabled = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _isButtonDisabled = false);
      }
      setState(() => _countdown--);
    });
  }

  Future<void> requestOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng nhập số điện thoại'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    try {
      final authService = AuthService();

      final response = await authService.getOTPService(
          {'phone': phone, 'fcm_token': _fcmToken, "type": "otp_login"});

      if (response != null && response['status'] == 'success') {
        final data = response['data'] as Map<String, dynamic>?;
        final String? lastOTP = data?['lastOTP'] as String?;

        startCountdown();
        await _showOTPNotification(phone: phone, lastOTP: lastOTP);

        // if (mounted) {
        //   final String message = response['message'] as String? ??
        //       'Đã gửi mã OTP đến số điện thoại của bạn';
        //
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(message),
        //       backgroundColor: const Color(0xFF27AE60),
        //       behavior: SnackBarBehavior.floating,
        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        //       duration: const Duration(seconds: 2),
        //     ),
        //   );
        // }

        if (mounted) {
          context.go('${GlobalRouterConfig.confirmLoginOTP}/$phone');
        }
      } else {
        final String errMsg = response?['message'] as String? ?? 'Có lỗi xảy ra';
        if (mounted) SnackBarHelper.showError(context, errMsg);
      }
    } catch (error) {
      appLog('Lỗi requestOTP: $error');
      if (mounted) {
        SnackBarHelper.showError(context, 'Đã xảy ra lỗi: $error');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button - minimal
                GestureDetector(
                  onTap: () => context.go(CustomerRouterConfig.homeCustomer),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Logo/Brand - simple and clean
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Đăng nhập bằng số điện thoại',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Phone input - clean card
                Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số điện thoại',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1A1A1A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại của bạn',
                          hintStyle: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: BorderSide(
                              color: ColorConfig.primary,
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // OTP Button - minimal but elegant
                GestureDetector(
                  onTap: _isButtonDisabled ? null : requestOTP,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _isButtonDisabled
                          ? const Color(0xFFCCCCCC)
                          : ColorConfig.primary,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: _isButtonDisabled
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gửi lại sau $_countdown giây',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                          : const Text(
                        'Tiếp tục',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Đăng nhập bằng mật khẩu',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/get-otp'),
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Chưa có tài khoản?',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => context.go(GlobalRouterConfig.register),
                            child: Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: ColorConfig.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}