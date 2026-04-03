import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
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
  late Animation<Offset> _slideAnim;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _getFCMToken();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _animController.forward();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(settings);
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
    final phone = _phoneController.text;
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vui lòng nhập số điện thoại.'),
            backgroundColor: const Color(0xFF8B6F61),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }
    try {
      final authService = AuthService();
      final response = await authService.getOTPService(
          {'phone': phone, 'fcm_token': _fcmToken, "type": "otp_login"});
      print(response);
      context.go('${GlobalRouterConfig.confirmLoginOTP}/$phone');
    } catch (error) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Đã xảy ra lỗi: $error');
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
    // Spa color palette
    const Color creamBg = Color(0xFFFAF6F1);
    const Color roseTaupe = Color(0xFF9C7B6E);
    const Color warmBrown = Color(0xFF6B4C41);
    const Color softGold = Color(0xFFBFA07A);
    const Color mutedSage = Color(0xFF8A9E8C);
    const Color textDark = Color(0xFF3A2E2A);
    const Color inputBg = Color(0xFFF3EDE7);

    return Scaffold(
      backgroundColor: creamBg,
      body: Stack(
        children: [
          // Decorative top arc
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: softGold.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            top: -40,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mutedSage.withOpacity(0.10),
              ),
            ),
          ),
          // Bottom decoration
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: roseTaupe.withOpacity(0.10),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => context.go(CustomerRouterConfig.homeCustomer),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: softGold.withOpacity(0.4), width: 1),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: warmBrown),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Logo + Brand
                      Center(
                        child: Column(
                          children: [
                            // Logo container
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: softGold.withOpacity(0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Image.asset(
                                    'lib/assets/images/spa_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Serene Spa',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: warmBrown,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 24,
                                    height: 1,
                                    color: softGold.withOpacity(0.6)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Thư giãn & làm đẹp',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: roseTaupe,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                    width: 24,
                                    height: 1,
                                    color: softGold.withOpacity(0.6)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: warmBrown.withOpacity(0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Đăng nhập bằng OTP',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Nhập số điện thoại để nhận mã xác thực',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: roseTaupe,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Phone field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số điện thoại',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: warmBrown,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: textDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0901 234 567',
                                    hintStyle: TextStyle(
                                      color: roseTaupe.withOpacity(0.5),
                                      fontSize: 15,
                                    ),
                                    filled: true,
                                    fillColor: inputBg,
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14),
                                      child: Icon(Icons.phone_outlined,
                                          size: 20,
                                          color: softGold.withOpacity(0.9)),
                                    ),
                                    prefixIconConstraints:
                                    const BoxConstraints(minWidth: 50),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                          color: softGold.withOpacity(0.2),
                                          width: 1.2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: softGold, width: 1.6),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 16),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // OTP Button
                            AnimatedOpacity(
                              opacity: _isButtonDisabled ? 0.65 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: _isButtonDisabled ? null : requestOTP,
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: _isButtonDisabled
                                        ? LinearGradient(
                                      colors: [
                                        roseTaupe.withOpacity(0.6),
                                        roseTaupe.withOpacity(0.4),
                                      ],
                                    )
                                        : const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF9C7B6E),
                                        Color(0xFF6B4C41),
                                      ],
                                    ),
                                    boxShadow: _isButtonDisabled
                                        ? []
                                        : [
                                      BoxShadow(
                                        color:
                                        roseTaupe.withOpacity(0.40),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isButtonDisabled
                                        ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.timer_outlined,
                                            color: Colors.white70,
                                            size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Gửi lại sau $_countdown giây',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    )
                                        : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            Icons
                                                .lock_open_outlined,
                                            color: Colors.white,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Lấy mã OTP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            TextButton(
                              onPressed: () => context.go(GlobalRouterConfig.register),
                              child: Text("Đã có tài khoản? Đăng ký", style: TextStyle(color: Colors.black),),

                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Footer links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FooterLink(
                            label: 'Đăng nhập bằng mật khẩu',
                            onTap: () => context.go('/login'),
                            color: roseTaupe,
                          ),
                          Container(
                              width: 1,
                              height: 14,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 12),
                              color: softGold.withOpacity(0.4)),
                          _FooterLink(
                            label: 'Quên mật khẩu?',
                            onTap: () => context.go('/get-otp'),
                            color: mutedSage,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Bottom brand line
                      Center(
                        child: Text(
                          '✦  Serene Spa  ✦',
                          style: TextStyle(
                            fontSize: 11,
                            color: softGold.withOpacity(0.55),
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _FooterLink({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: color.withOpacity(0.4),
        ),
      ),
    );
  }
}