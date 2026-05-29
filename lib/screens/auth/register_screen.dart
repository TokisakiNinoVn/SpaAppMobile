import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/services/auth_service.dart';

import '../../storage/index.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final fullnameController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  Future<void> handleRegister() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;
    final fullname = fullnameController.text.trim();

    if (phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ thông tin bắt buộc');
      return;
    }

    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      _showSnack('Số điện thoại phải có đúng 10 chữ số');
      return;
    }

    if (password.length < 6) {
      _showSnack('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Mật khẩu xác nhận không khớp');
      return;
    }

    if (fullname.isEmpty) {
      _showSnack('Vui lòng nhập họ và tên');
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.registerService({
        "phone": phone,
        "password": password,
        "roles": "customer",
        "fullname": fullname,
      });

      if (response['status'] == 'success') {
        SnackBarHelper.showSuccess(context, "Đăng ký tài khoản thành công");
        await SharedPrefs.saveValue(PrefType.string, "token", response['token']);
        await SharedPrefs.saveValue(PrefType.string, "inforUserLogin", response['data']);

        await SharedPrefs.saveValue(PrefType.string, "role", response['data']?['rolesActive']);
        await SharedPrefs.saveValue(PrefType.bool, "isLogin", true);
        await SharedPrefs.saveValue(PrefType.bool, "isHaveTechnician", false);
        // await SharedPrefs.saveValue(PrefType.bool, "isTechnicianActive", response['data']?['isTechnicianActive'] ?? false);
        await SharedPrefs.saveValue(PrefType.bool, "isTechnicianActive", false);
        await SharedPrefs.saveValue(PrefType.string, "customerProfile", response['data']?['customerProfile']?? {});
        await SharedPrefs.saveValue(PrefType.int, "balance", response['data']?['customerProfile']?['balance'] ?? 0);

        context.go(CustomerRouterConfig.homeCustomer);
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi hệ thống: $e');
      print("Lỗi đăng ký: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFE74C3C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullnameController.dispose();
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                'lib/assets/images/zen-hone-circle-logo.png',
                height: 90,
              ),

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
                'Đăng ký tài khoản',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 20),

              _buildTextField(
                controller: fullnameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
                inputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

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
                inputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Confirm password field
              _buildTextField(
                controller: confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                icon: Icons.lock_outline,
                obscure: !showConfirmPassword,
                suffix: IconButton(
                  icon: Icon(
                    showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF999999),
                    size: 20,
                  ),
                  onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                ),
                inputAction: TextInputAction.done,
              ),

              const SizedBox(height: 32),

              // Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : handleRegister,
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
                    'Đăng ký',
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
                      'Đã có tài khoản?',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: ColorConfig.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: () => context.push('/register-partner'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đăng ký đối tác với',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${AppConfig.appName}',
                      style: TextStyle(
                        color: ColorConfig.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Footer info
              Column(
                children: [
                  Text(
                    'Phiên bản: 2.4.1.23',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Liên hệ: ${AppConfig.emailAppSupport}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
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