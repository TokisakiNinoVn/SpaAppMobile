import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
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
  bool _isRequestingOTP = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _getFCMToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        appLog('User từ chối permission notification');
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Bạn cần cho phép thông báo để nhận mã OTP. Vui lòng bật quyền thông báo trong cài đặt.',
          );
        }
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          appLog('APNs token null — chạy trên simulator hoặc chưa config APNs');
          if (mounted) {
            SnackBarHelper.showError(
              context,
              'Không thể lấy APNs token. Vui lòng chạy trên thiết bị thật và đảm bảo đã cấu hình APNs đúng cách.',
            );
          }
          return;
        }
        appLog('APNs token: $apnsToken');
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        setState(() => _fcmToken = token);
      } else {
        if (mounted) {
          SnackBarHelper.showError(
            context,
            'Không thể lấy FCM token. Vui lòng thử lại hoặc kiểm tra cấu hình Firebase.',
          );
        }
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
    if (_isRequestingOTP || _isButtonDisabled) return;

    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      SnackBarHelper.showWarning(context, "Vui lòng nhập số điện thoại");
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

    if (_fcmToken == null) {
      await _getFCMToken();
    }

    setState(() {
      _isRequestingOTP = true;
      _isButtonDisabled = true; // Disable ngay lập tức để tránh spam
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

          context.push(
            '${GlobalRouterConfig.confirmLoginOTP}/$phone',
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
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = _isButtonDisabled || _isRequestingOTP;

    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back / Home button
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
                      Icons.home,
                      size: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Brand header
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

                // Phone input
                Column(
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
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
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

                const SizedBox(height: 32),

                // CTA button
                GestureDetector(
                  onTap: isDisabled ? null : requestOTP,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDisabled
                          ? const Color(0xFFCCCCCC)
                          : ColorConfig.primary,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
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
                        onPressed: () => context.push(GlobalRouterConfig.login),
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
                        onPressed: () => context.push('/get-otp'),
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
                      GestureDetector(
                        onTap: () => context.push(GlobalRouterConfig.register),
                        child: Row(
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
                            Text(
                              'Đăng ký ngay',
                              style: TextStyle(
                                color: ColorConfig.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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