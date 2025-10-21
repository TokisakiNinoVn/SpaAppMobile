import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

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

  final String urlPrivacy = "https://serene-spa-green.vercel.app/privacy";
  final String urlSupport = "https://serene-spa-green.vercel.app/support";

  @override
  void initState() {
    super.initState();
    _loadLoginData();
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
        debugPrint('Lỗi khi parse loginData: $e');
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

    setState(() => isLoading = true);

    try {
      final response = await authService.loginService({
        "phone": phone,
        "password": password,
      });

      final prefs = await SharedPreferences.getInstance();

      if (response['token'] != null) {
        try {
          await prefs.setString('token', response['token']);
          await prefs.setString('isLogin', 'true');
          await prefs.setString('inforUserLogin', jsonEncode(response['data']));
          await prefs.setString('role', jsonEncode(response['data']?['role']));
          await prefs.setBool('rememberMe', rememberMe);

          // Status
          await prefs.setString('statusAccount', jsonEncode(response['data']?['status']));
          await prefs.setString('isTechnicianActive', jsonEncode(response['data']['isTechnicianActive']));

          final bool isHaveTechnician = response['data']['isHaveTechnician'];
          // final bool isTechnicianActive = response['data']['isTechnicianActive'];

          if (rememberMe) {
            final loginInfo = jsonEncode({
              'phone': phone,
              'password': password,
            });
            await prefs.setString('loginData', loginInfo);
          } else {
            await prefs.remove('loginData');
          }

          if (response['data']['role'] == 'admin') {
            context.go('/home-admin');

          } else if (response['data']['role'] == 'ktv') {
            await prefs.setString('statusAccount', jsonEncode(response['data']?['status']));
            await prefs.setString('isTechnicianActive', jsonEncode(response['data']?['isTechnicianActive']));
            if (isHaveTechnician == true) {
              await prefs.setString('technician', jsonEncode(response['data']?['technicianProfile']));
              context.go('/home-technician');
            } else {
              SnackbarHelper.showWarning(context, "Bạn đã đăng ký tài khoản nhưng chưa tạo hồ sơ!");
              context.go('/create-technician');
            }
          } else if (response['data']['role'] == 'quanly') {
            context.go('/home-quanly');
          } else if (response['data']['role'] == 'customer') {
            context.go('/home-customer');
          }
        } catch (e) {
          SnackbarHelper.showError(context, "Lỗi gì đó ở đoạn lưu thông tin đăng nhập: $e");
        }
      } else {
        // _showSnack(response['message'] ?? ');
        SnackbarHelper.showError(context,response['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      SnackbarHelper.showError(context, "Lỗi hệ thống: $e");
    } finally {
      setState(() => isLoading = false);
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'lib/assets/images/spa_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  'Serene Spa',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: ColorConfig.primary,
                  ),
                ),
                Text(
                  'Thư giãn & làm đẹp',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    color: ColorConfig.primary,
                  ),
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: phoneController,
                  label: 'Số điện thoại',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: passwordController,
                  label: 'Mật khẩu',
                  icon: Icons.lock,
                  obscure: !showPassword,
                  suffix: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility : Icons.visibility_off,
                      color: ColorConfig.primary,
                    ),
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
                      checkColor: ColorConfig.white,
                      activeColor: ColorConfig.secondary,
                    ),
                    Text(
                      'Ghi nhớ đăng nhập',
                      style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: ColorConfig.secondary,
                      foregroundColor: ColorConfig.primaryBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      'Đăng nhập',
                      style: ThemeConfig.appTextStyle(color: ColorConfig.textButtonColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bạn chưa có tài khoản?',
                            style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đăng ký',
                            style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.go('/get-otp');
                  },
                  child: Text(
                    'Quên mật khẩu?',
                    style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),
                // Thêm 2 link Privacy và Support
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse(urlPrivacy));
                      },
                      child: Text(
                        'Privacy Policy',
                        style: ThemeConfig.appTextStyle(
                          color: ColorConfig.primary,
                          fontSize: 12,
                          // decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      color: ColorConfig.textPrimary,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    TextButton(
                      onPressed: () {
                        launchUrl(Uri.parse(urlSupport));
                      },
                      child: Text(
                        'Support',
                        style: ThemeConfig.appTextStyle(
                          color: ColorConfig.primary,
                          fontSize: 12,
                          // decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text(
                      'Phiên bản: 2.4.1.23',
                      style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Liên hệ: support@serenespa.vn',
                      style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}