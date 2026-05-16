import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/services/auth_service.dart';

import '../../../helper/snackbar_helper.dart';

class OTPForgotPasswordScreen extends StatefulWidget {
  @override
  _OTPForgotPasswordScreenState createState() => _OTPForgotPasswordScreenState();
}

class _OTPForgotPasswordScreenState extends State<OTPForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isButtonDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  String? _fcmToken;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getFCMToken();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);
  }

  Future<void> _getFCMToken() async {
    final isSupport = FirebaseMessaging.instance.isSupported();
    final idHii = await FirebaseInstallations.instance.getId();
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        setState(() {
          _fcmToken = token;
        });
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        _updateFCMTokenIfLoggedIn(newToken);
      });
    } catch (e) {
      appLog("Lỗi lấy FCM token: $e");
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

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'otp_channel',
      'OTP Notifications',
      channelDescription: 'Thông báo OTP',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      'Mã OTP',
      message,
      platformDetails,
    );
  }

  void startCountdown() {
    setState(() {
      _countdown = 60;
      _isButtonDisabled = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _isButtonDisabled = false;
        });
      }
      setState(() {
        _countdown--;
      });
    });
  }

  Future<void> requestOTP() async {
    final phone = _phoneController.text;

    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng nhập số điện thoại'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        );
      }
      return;
    }

    try {
      final authService = AuthService();
      final response = await authService.getOTPService({'phone': phone, "type": "otp_forgot_password", 'fcm_token': _fcmToken});
      print(response);
      if (response['success'] == true || response['status'] == 'success') {
        final message = response['message'] ?? 'Mã OTP đã được gửi';
        await _showNotification(message);
        startCountdown();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text('Đã gửi mã OTP'),
                ],
              ),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          context.push('/get-otp/confirm-otp/$phone');
        }
      } else {
        if (mounted) {
          SnackBarHelper.showError(context, response['message'] ?? 'Yêu cầu OTP thất bại');
        }
      }
    } catch (error) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Đã xảy ra lỗi: $error');
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConfig.primaryBackground,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.push(GlobalRouterConfig.loginOTP);
                }
              },
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            // const SizedBox(width: 16),
            // const Expanded(
            //   child: Text(
            //     "Đăng nhập bằng OTP",
            //     style: TextStyle(
            //       color: Color(0xFF1A1A1A),
            //       fontWeight: FontWeight.w600,
            //       fontSize: 16,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // const SizedBox(height: 20),
              //
              // // Back button
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: GestureDetector(
              //     onTap: () => context.pop(),
              //     child: Container(
              //       width: 40,
              //       height: 40,
              //       decoration: BoxDecoration(
              //         color: const Color(0xFFF5F5F5),
              //         borderRadius: BorderRadius.circular(40),
              //       ),
              //       child: const Icon(
              //         Icons.arrow_back_ios_new_rounded,
              //         size: 18,
              //         color: Color(0xFF333333),
              //       ),
              //     ),
              //   ),
              // ),
              //
              // const SizedBox(height: 40),

              // Icon header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConfig.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Nhập số điện thoại để nhận mã OTP',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 48),

              // Phone field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  labelStyle: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.phone_outlined,
                    color: Color(0xFF999999),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                    borderSide: BorderSide(color: ColorConfig.textPrimary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                ),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 32),

              // Get OTP button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isButtonDisabled ? null : requestOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  child: _isButtonDisabled
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          value: _countdown / 60,
                          strokeWidth: 2,
                          backgroundColor: Colors.grey.shade700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Gửi lại sau $_countdown giây',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                      : const Text(
                    'Lấy mã OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 12,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Quay lại đăng nhập',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Decorative line with text
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade200,
                      thickness: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Cần hỗ trợ?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey.shade200,
                      thickness: 0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Support contact
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${AppConfig.emailAppSupport}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  // const SizedBox(width: 16),
                  // Icon(
                  //   Icons.phone_outlined,
                  //   size: 14,
                  //   color: Colors.grey.shade400,
                  // ),
                  // const SizedBox(width: 6),
                  // Text(
                  //   '1900 1234',
                  //   style: TextStyle(
                  //     fontSize: 12,
                  //     color: Colors.grey.shade400,
                  //   ),
                  // ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}