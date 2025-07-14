import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:spa_app/services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLoginData();
  }

  Future<void> _loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('rememberMe') ?? false;
    final token = prefs.getString('token');
    final isLogin = prefs.getString('isLogin');

    // if (token != null && isLogin == 'true') {
    //   context.go('/home');
    // } else {
    //   context.go('/login');
    // }
    //
    // final response = await authService.checkTokenService();
    // if (response['success'] == true || response['status'] == 'success') {
    //   context.go('/home');
    // } else {
    //   prefs.remove('token');
    //   context.go('/login');
    // }

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
      _showSnack('Vui lòng nhập đầy đủ thông tin');
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
        await prefs.setString('token', response['token']);
        await prefs.setString('isLogin', 'true');
        await prefs.setString('inforUserLogin', jsonEncode(response['data']));
        await prefs.setString('role', jsonEncode(response['data']?['role']));
        await prefs.setBool('rememberMe', rememberMe);

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
          context.go('/home-technician');
        } else if (response['data']['role'] == 'customer') {
          context.go('/home-customer');
        }

        // context.go('/home');
        _showSnack('Đăng nhập thành công!');
      } else {
        _showSnack(response['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      _showSnack('Lỗi hệ thống: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lora(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
        prefixIcon: Icon(icon, color: const Color(0xFF8B5E3C)),
        suffixIcon: suffix,
        labelStyle: GoogleFonts.lora(
          color: const Color(0xFF8B5E3C),
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: GoogleFonts.lora(
        color: Colors.black87,
        fontSize: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // decoration: const BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage('assets/images/spa_background.jpg'),
        //     fit: BoxFit.cover,
        //     opacity: 0.3,
        //   ),
        //   gradient: LinearGradient(
        //     colors: [Color(0xFFF8EDEB), Color(0xFFF3D2C1)],
        //     begin: Alignment.topCenter,
        //     end: Alignment.bottomCenter,
        //   ),
        // ),
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
                    color: const Color(0xFF8B5E3C),
                  ),
                ),
                Text(
                  'Thư giãn & làm đẹp',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    color: const Color(0xFF8B5E3C),
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
                      color: const Color(0xFF8B5E3C),
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
                      checkColor: Colors.white,
                      activeColor: const Color(0xFFD4A373),
                    ),
                    Text(
                      'Ghi nhớ đăng nhập',
                      style: GoogleFonts.lora(
                        color: const Color(0xFF8B5E3C),
                        fontSize: 14,
                      ),
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
                      backgroundColor: const Color(0xFFD4A373),
                      foregroundColor: Colors.white,
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
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: Text(
                    'Bạn chưa có tài khoản? Đăng ký',
                    style: GoogleFonts.lora(
                      color: const Color(0xFF8B5E3C),
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showSnack('Chức năng này chưa được triển khai'),
                  child: Text(
                    'Quên mật khẩu?',
                    style: GoogleFonts.lora(
                      color: const Color(0xFF8B5E3C),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    Text(
                      'Phiên bản: 2.4.1.23',
                      style: GoogleFonts.lora(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Liên hệ: support@serenespa.vn',
                      style: GoogleFonts.lora(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
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