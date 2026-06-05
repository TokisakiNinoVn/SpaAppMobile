import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/global_router_config.dart';

import '../../../helper/snackbar_helper.dart';

class OTPForgotPasswordScreen extends StatefulWidget {
  @override
  _OTPForgotPasswordScreenState createState() => _OTPForgotPasswordScreenState();
}

class _OTPForgotPasswordScreenState extends State<OTPForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isRequestingOTP = false;
  bool _isButtonDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        setState(() => _fcmToken = token);
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
    if (_isRequestingOTP || _isButtonDisabled) return;

    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      if (mounted) SnackBarHelper.showWarning(context, "Vui lòng nhập số điện thoại");
      return;
    }

    final phoneRegex = RegExp(r'^0\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      SnackBarHelper.showWarning(
        context,
        "Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0",
      );
      return;
    }

    // Disable ngay lập tức để tránh spam
    setState(() {
      _isRequestingOTP = true;
      _isButtonDisabled = true;
    });

    try {
      final phoneInternational = FormatHelper.formatPhoneInternational(phone);

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneInternational,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },

        verificationFailed: (FirebaseAuthException e) {
          appLog('verifyPhoneNumber error: ${e.code} - ${e.message}');

          if (!mounted) return;

          // Re-enable nút nếu request thất bại
          setState(() => _isButtonDisabled = false);

          String message;
          switch (e.code) {
            case 'too-many-requests':
              message = 'Bạn đã yêu cầu OTP quá nhiều lần. Vui lòng thử lại sau.';
              break;
            case 'invalid-phone-number':
              message = 'Số điện thoại không hợp lệ.';
              break;
            case 'quota-exceeded':
              message = 'Hệ thống OTP đang quá tải. Vui lòng thử lại sau.';
              break;
            default:
              message = e.message ?? 'Không thể gửi OTP.';
          }

          SnackBarHelper.showError(context, message);
        },

        codeSent: (verificationId, resendToken) {
          startCountdown();

          if (!mounted) return;
          SnackBarHelper.showSuccess(context, 'Đã gửi mã OTP đến số điện thoại của bạn');

          context.push(
            '/get-otp/confirm-otp/$phone',
            extra: {
              'verificationId': verificationId,
              'resendToken': resendToken,
            },
          ).then((_) {
            if (mounted) setState(() => _isRequestingOTP = false);
          });
        },

        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      appLog('FirebaseAuthException: ${e.code}');
      if (mounted) {
        setState(() => _isButtonDisabled = false); // Re-enable khi lỗi
        SnackBarHelper.showError(context, 'Lỗi xác thực: ${e.message}');
      }
    } catch (e) {
      appLog('requestOTP error: $e');
      if (mounted) {
        setState(() => _isButtonDisabled = false); // Re-enable khi lỗi
        SnackBarHelper.showError(context, 'Không thể gửi OTP. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingOTP = false);
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
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
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
                  onPressed: (_isButtonDisabled || _isRequestingOTP) ? null : requestOTP,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  child: _isRequestingOTP
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : _isButtonDisabled
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
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 12,
                      color: Color(0xFF666666),
                    ),
                    SizedBox(width: 4),
                    Text(
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

              // Decorative divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade200, thickness: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Cần hỗ trợ?',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade200, thickness: 0.5)),
                ],
              ),

              const SizedBox(height: 16),

              // Support email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    '${AppConfig.emailAppSupport}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
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