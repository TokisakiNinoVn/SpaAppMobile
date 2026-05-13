import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import '../../../helper/snackbar_helper.dart';
import 'package:spa_app/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String phone;
  const ResetPasswordScreen({Key? key, required this.phone});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final authService = AuthService();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _rePasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureNewPass = true;
  bool _obscureRePass = true;

  Future<void> resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final rePassword = _rePasswordController.text.trim();

    if (newPassword.isEmpty || rePassword.isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập đủ thông tin');
      return;
    }
    if (newPassword != rePassword) {
      SnackBarHelper.showError(context, 'Mật khẩu nhập lại không khớp');
      return;
    }
    if (newPassword.length < 6) {
      SnackBarHelper.showError(context, 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await authService.changePasswordService({
        'phone': widget.phone,
        'newPassword': newPassword,
      });

      if (response['success'] == true || response['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Đặt lại mật khẩu thành công'),
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
          context.go('/login');
        }
      } else {
        SnackBarHelper.showError(context, response['error'] ?? 'Đặt lại mật khẩu thất bại');
      }
    } catch (error) {
      SnackBarHelper.showError(context, 'Đã xảy ra lỗi: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF999999),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF999999),
            size: 20,
          ),
          onPressed: onToggle,
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Icon header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: ColorConfig.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Đặt lại mật khẩu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: ColorConfig.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 14,
                      color: Color(0xFF666666),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(10),
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
                          'Yêu cầu mật khẩu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      'Ít nhất 6 ký tự',
                      _newPasswordController.text.length >= 6,
                    ),
                    const SizedBox(height: 6),
                    _buildRequirementItem(
                      'Có chữ và số',
                      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(_newPasswordController.text),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // New password field
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'Mật khẩu mới',
                obscureText: _obscureNewPass,
                onToggle: () => setState(() => _obscureNewPass = !_obscureNewPass),
              ),

              const SizedBox(height: 16),

              // Confirm password field
              _buildPasswordField(
                controller: _rePasswordController,
                label: 'Nhập lại mật khẩu mới',
                obscureText: _obscureRePass,
                onToggle: () => setState(() => _obscureRePass = !_obscureRePass),
              ),

              const SizedBox(height: 32),

              // Reset button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Đặt lại mật khẩu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Back to login link
              TextButton(
                onPressed: () => context.go(GlobalRouterConfig.loginOTP),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

              // Password requirements section

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? const Color(0xFF27AE60) : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? const Color(0xFF666666) : Colors.grey.shade500,
            decoration: isMet ? TextDecoration.lineThrough : null,
            decorationColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}