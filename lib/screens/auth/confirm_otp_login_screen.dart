import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../api/services/auth_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';

import '../../../helper/snackbar_helper.dart';
import '../../../services/auth_service.dart';

class ConfirmOTPScreen extends StatefulWidget {
  final String phone;
  const ConfirmOTPScreen({Key? key, required this.phone}) : super(key: key);

  @override
  _ConfirmOTPScreenState createState() => _ConfirmOTPScreenState();
}

class _ConfirmOTPScreenState extends State<ConfirmOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isButtonDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> verifyOTP() async {
    String otp = _controllers.map((controller) => controller.text).join('');
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ mã OTP.')),
      );
      return;
    }

    try {
      final response = await AuthService().verifyOTPService({
        'phone': widget.phone,
        'otp': otp,
      });

      print("Response confirm otp: $response");

      if (response['success'] == true || response['status'] == 'success') {
        context.go('/reset-password/${widget.phone}');
      } else {
        _clearAllFields();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Xác minh thất bại.')),
        );
      }
    } catch (error) {
      _clearAllFields();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $error')),
      );
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
    await _localNotifications.show(0, 'Mã OTP đổi mật khẩu', message, platformDetails);
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
    final phone = widget.phone;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số điện thoại.')));
      return;
    }

    try {
      final authService = AuthService();
      final response = await authService.getOTPService({'phone': phone});
      print("response confirm otp: $response");
      if (response['success'] == true || response['status'] == 'success') {
        final message = response['message'] ?? 'Mã OTP đã được gửi.';
        await _showNotification(message);
        startCountdown();
        // context.go('/confirm-otp/$phone');
      } else {
        SnackbarHelper.showError(context, response['error'] ?? 'Yêu cầu OTP thất bại.');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã xảy ra lỗi: $error')));
    }
  }

  void _onFieldChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }

    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      verifyOTP();
    }
  }

  void _clearAllFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Xác nhận mã OTP',
          style: ThemeConfig.appTextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorConfig.primary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Thông tin gửi OTP
            Text(
              'Mã xác thực đã được gửi tới số điện thoại',
              textAlign: TextAlign.center,
              style: ThemeConfig.appTextStyle(
                fontSize: 16,
                color: ColorConfig.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.phone,
              style: ThemeConfig.appTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConfig.textPrimary,
              ),
            ),

            const SizedBox(height: 30),

            // Nhập OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 40,
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(bottom: 4),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (value) => _onFieldChanged(value, index),
                  ),
                );
              }),
            ),

            const SizedBox(height: 30),

            // Nút xác nhận
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Gửi lại OTP
            Text(
              'Không nhận được mã xác thực?',
              style: ThemeConfig.appTextStyle(fontSize: 15, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonDisabled ? null : requestOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonDisabled ? Colors.grey : ColorConfig.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isButtonDisabled ? 'Chờ $_countdown giây' : 'Gửi lại mã OTP',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
