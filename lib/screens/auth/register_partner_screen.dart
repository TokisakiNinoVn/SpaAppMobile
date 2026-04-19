import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/auth_service.dart';

class RegisterPartnerScreen extends StatefulWidget {
  const RegisterPartnerScreen({super.key});

  @override
  State<RegisterPartnerScreen> createState() => _RegisterPartnerScreenState();
}

class _RegisterPartnerScreenState extends State<RegisterPartnerScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final authService = AuthService();

  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  Future<void> handleRegister() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Validation
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

    setState(() => isLoading = true);

    try {
      final response = await authService.registerService({
        "phone": phone,
        "password": password,
        "roles": "ktv", // Fixed role as ktv
      });

      if (response['status'] == 'success') {
        if (response['isHaveTechnician'] == false) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response['token']);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Đăng ký tài khoản thành công!'),
                  ],
                ),
                backgroundColor: const Color(0xFF27AE60),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            context.go('/create-technician');
          }
        }
      } else {
        SnackbarHelper.showError(context, response['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi hệ thống: $e');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.go('/register'),
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
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),

              Text(
                'Đăng ký đối tác',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.primary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Trở thành kỹ thuật viên của ${AppConfig.appName}',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: ColorConfig.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kỹ thuật viên',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorConfig.primary,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Text(
                        'KTV',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

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

              // Login link
              TextButton(
                onPressed: () => context.go('/login'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      TextSpan(text: 'Đã có tài khoản? '),
                      TextSpan(
                        text: 'Đăng nhập',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Thông tin đăng ký',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(Icons.verified_user_rounded, 'Đăng ký với vai trò Kỹ thuật viên'),
                    const SizedBox(height: 8),
                    _buildInfoItem(Icons.work_outline, 'Cần tạo hồ sơ kỹ thuật viên sau khi đăng ký'),
                    const SizedBox(height: 8),
                    _buildInfoItem(Icons.security_rounded, 'Tài khoản sẽ được xác thực bởi quản trị viên'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Footer
              Column(
                children: [
                  Text(
                    'Phiên bản: 2.4.1.23',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Liên hệ: support@serenespa.vn',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
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

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}