import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

import '../../helper/logger_utils.dart';
import '../../storage/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  bool showPassword = false;
  bool rememberMe = true;
  bool isLogin = false;

  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadLoginData();
    _getFCMToken();
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

  Future<void> _loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberMe') ?? false;

    if (!remember) return;

    final loginData = prefs.getString('loginData');
    if (loginData != null) {
      try {
        final parsed = jsonDecode(loginData);
        phoneController.text = parsed['phone'] ?? '';
        passwordController.text = parsed['password'] ?? '';
        setState(() => rememberMe = true);
      } catch (e) {
        debugPrint('Lỗi parse loginData: $e');
      }
    }
  }

  Future<void> handleLogin() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      SnackBarHelper.showError(context, "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    final fcm = _fcmToken ?? '';

    setState(() => isLoading = true);

    try {
      final response = await authService.loginService({
        "phone": phone,
        "password": password,
        "fcm_token": fcm,
        "device_type": "android",
      });

      // appLog("response $response");
      if(response["status"] == "error") {
        SnackBarHelper.showError(context, "${response["message"]}");
        return;
      }

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );
    } catch (e) {
      appLog('Lỗi đăng nhập: $e');

      SnackBarHelper.showError(
        context,
        "Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!",
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputAction inputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: inputAction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: ColorConfig.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Image.asset(
                'lib/assets/images/zen-hone-circle-logo.png',
                height: 100,
              ),

              const SizedBox(height: 10),

              Text(
                AppConfig.appNameUpperCase,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Thư giãn & làm đẹp',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 20),

              // Phone field
              _buildTextField(
                controller: phoneController,
                label: 'Số điện thoại',
                icon: Icons.phone_outlined,
                inputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Password field
              _buildTextField(
                controller: passwordController,
                label: 'Mật khẩu',
                icon: Icons.lock_outline,
                obscure: !showPassword,
                suffix: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF999999),
                    size: 20,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
                inputAction: TextInputAction.done,
              ),

              const SizedBox(height: 12),

              // Remember me checkbox
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (val) => setState(() => rememberMe = val ?? true),
                    checkColor: Colors.white,
                    activeColor: ColorConfig.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'Ghi nhớ đăng nhập',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => context.push(GlobalRouterConfig.loginOTP),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đăng nhập bằng',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                      Text(
                      'OTP',
                      style: TextStyle(
                        color: ColorConfig.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
                      'Đăng ký',
                      style: TextStyle(
                        color: ColorConfig.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () => context.push(GlobalRouterConfig.getOptForgotPassword),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Footer links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(AppConfig.urlPrivacy)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 12,
                    color: const Color(0xFFE0E0E0),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(Uri.parse(AppConfig.urlSupport)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Support',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),

              // const SizedBox(height: 16),
              //
              // Text(
              //   'Phiên bản: 2.4.1.23',
              //   style: TextStyle(
              //     fontSize: 11,
              //     color: Colors.grey.shade400,
              //   ),
              // ),
              //
              // const SizedBox(height: 4),
              //
              // Text(
              //   'Liên hệ: support@serenespa.vn',
              //   style: TextStyle(
              //     fontSize: 11,
              //     color: Colors.grey.shade400,
              //   ),
              // ),
              //
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}