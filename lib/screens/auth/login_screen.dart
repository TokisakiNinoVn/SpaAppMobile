import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

import '../helper/logger_utils.dart';

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

  // Lấy FCM Token từ Firebase
  Future<void> _getFCMToken() async {
    final isSupport = FirebaseMessaging.instance.isSupported();
    final idHii = await FirebaseInstallations.instance.getId();
    // appLog("isSupport: $isSupport");
    // appLog("idHii: $idHii");
    try {
      // Xóa token FCM hiện tại
      // await FirebaseMessaging.instance.deleteToken();
      //
      // // Xóa Installation ID → ép Firebase tạo FID mới
      // await FirebaseInstallations.instance.delete();

      // Xin quyền (Android 13+ yêu cầu)
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
        // debugPrint('FCM Token: $token');
      }

      // Lắng nghe khi token được refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        // Có thể gọi API cập nhật token mới ở đây nếu user đã đăng nhập
        _updateFCMTokenIfLoggedIn(newToken);
      });
    } catch (e) {
      appLog("Lỗi lấy FCM token: $e");
    }
  }

  // Nếu user đã đăng nhập trước đó, cập nhật lại token mới
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
      SnackbarHelper.showError(context, "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    final fcm = _fcmToken ?? '';

    setState(() => isLoading = true);

    try {
      // Gửi kèm FCM token trong request login
      final response = await authService.loginService({
        "phone": phone,
        "password": password,
        "fcm_token": fcm,
        "device_type": "android",
      });

      final prefs = await SharedPreferences.getInstance();

      if (response['token'] != null) {
        await prefs.setString('token', response['token']);
        await prefs.setBool('isLogin', true);
        await prefs.setString('inforUserLogin', jsonEncode(response['data']));
        await prefs.setString('role', jsonEncode(response['data']?['role']));
        await prefs.setBool('rememberMe', rememberMe);

        // Lưu thêm thông tin trạng thái
        await prefs.setString('statusAccount', jsonEncode(response['data']?['status']));
        await prefs.setString('isTechnicianActive', jsonEncode(response['data']?['isTechnicianActive'] ?? false));

        if (rememberMe) {
          await prefs.setString('loginData', jsonEncode({
            'phone': phone,
            'password': password,
          }));
        } else {
          await prefs.remove('loginData');
        }

        final role = response['data']?['role'];
        final isHaveTechnician = response['data']?['isHaveTechnician'] ?? false;

        if (role == 'admin') {
          context.go('/home-admin');
        } else if (role == 'ktv') {
          if (isHaveTechnician) {
            await prefs.setString('technician', jsonEncode(response['data']?['technicianProfile']));
            await prefs.setString('serviceIds', jsonEncode(response['data']?['technicianProfile']?['serviceIds'] ?? []));
            await prefs.setString(
              'inforService',
              jsonEncode(response['data']?['inforService'] ?? []),
            );

            context.go('/home-technician');
          } else {
            SnackbarHelper.showWarning(context, "Bạn đã đăng ký tài khoản nhưng chưa tạo hồ sơ!");
            context.go('/create-technician');
          }
        } else if (role == 'quanly') {
          context.go('/home-quanly');
        } else if (role == 'customer') {
          // await prefs.setString('isHaveTechnician', isHaveTechnician);
          await prefs.setString('customerProfile', jsonEncode(response['data']?['customerProfile']));
          context.go('/home-customer');
        }
      } else {
        SnackbarHelper.showError(context, response['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      SnackbarHelper.showError(context, "Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!");
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
        prefixIcon: Icon(icon, color: ColorConfig.iconColor),
        suffixIcon: suffix,
        labelStyle: ThemeConfig.appTextStyle(color: ColorConfig.textSecondary),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: ColorConfig.secondary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Image.asset('lib/assets/images/spa_logo.png', height: 100),
                const SizedBox(height: 16),
                // Text('Serene Spa', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold, color: ColorConfig.primary)),
                Text('Serene Spa', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ColorConfig.primary)),
                Text('Thư giãn & làm đẹp', style: TextStyle(fontSize: 18, color: ColorConfig.primary)),
                const SizedBox(height: 40),

                _buildTextField(controller: phoneController, label: 'Số điện thoại', icon: Icons.phone),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  label: 'Mật khẩu',
                  icon: Icons.lock,
                  obscure: !showPassword,
                  suffix: IconButton(
                    icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: ColorConfig.primary),
                    onPressed: () => setState(() => showPassword = !showPassword),
                  ),
                  inputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      onChanged: (val) => setState(() => rememberMe = val ?? true),
                      checkColor: Colors.white,
                      activeColor: ColorConfig.secondary,
                    ),
                    Text('Ghi nhớ đăng nhập', style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: ColorConfig.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(onPressed: () => context.go('/login-otp'), child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Đăng nhập bằng ', style: TextStyle(color: ColorConfig.textPrimary)),
                  TextSpan(text: 'OTP', style: TextStyle(fontWeight: FontWeight.bold, color: ColorConfig.textPrimary)),
                ]))),
                // const SizedBox(height: 20),
                TextButton(onPressed: () => context.go('/register'), child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'Chưa có tài khoản? ', style: TextStyle(color: ColorConfig.textPrimary)),
                  TextSpan(text: 'Đăng ký', style: TextStyle(fontWeight: FontWeight.bold, color: ColorConfig.textPrimary)),
                ]))),
                TextButton(onPressed: () => context.go('/get-otp'), child: Text('Quên mật khẩu?', style: TextStyle(color: ColorConfig.textPrimary))),

                const SizedBox(height: 40),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(onPressed: () => launchUrl(Uri.parse(AppConfig.urlPrivacy)), child:  Text('Privacy Policy', style: TextStyle(fontSize: 12, color: ColorConfig.textPrimary))),
                  Container(width: 1, height: 12, color: Colors.grey, margin: EdgeInsets.symmetric(horizontal: 12)),
                  TextButton(onPressed: () => launchUrl(Uri.parse(AppConfig.urlSupport)), child: Text('Support', style: TextStyle(fontSize: 12, color: ColorConfig.textPrimary))),
                ]),
                const SizedBox(height: 16),
                Text('Phiên bản: 2.4.1.23', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text('Liên hệ: support@serenespa.vn', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}