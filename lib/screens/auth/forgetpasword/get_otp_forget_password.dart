import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
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

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);
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
          const SnackBar(content: Text('Vui lòng nhập số điện thoại.')),
        );
      }
      return;
    }

    try {
      final authService = AuthService();
      final response = await authService.getOTPService({'phone': phone});
      print(response);
      if (response['success'] == true || response['status'] == 'success') {
        final message = response['message'] ?? 'Mã OTP đã được gửi.';
        await _showNotification(message);
        startCountdown();
        context.go('/get-otp/confirm-otp/$phone');
      } else {
        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text(response['error'] ?? 'Yêu cầu OTP thất bại.')),
          // );
          SnackbarHelper.showError(context, response['message'] ?? 'Yêu cầu OTP thất bại.');
        }
      }
    } catch (error) {
      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Đã xảy ra lỗi: $error')),
        // );
        SnackbarHelper.showError(context, 'Đã xảy ra lỗi: $error');
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
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Nhập số điện thoại để nhận mã OTP',
              style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                labelStyle: TextStyle(color: ColorConfig.primary),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConfig.primary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: ColorConfig.primary),
                ),
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isButtonDisabled ? null : requestOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isButtonDisabled ? 'Chờ $_countdown giây' : 'Lấy mã OTP',
                // style: const TextStyle(fontSize: 16),
                style: ThemeConfig.appTextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: Text(
                'Quay lại đăng nhập',
                style: TextStyle(color: ColorConfig.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
