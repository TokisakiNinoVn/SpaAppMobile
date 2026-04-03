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
      SnackbarHelper.showError(context, 'Vui lòng nhập đủ thông tin.');
      return;
    }
    if (newPassword != rePassword) {
      SnackbarHelper.showError(context, 'Mật khẩu nhập lại không khớp.');
      return;
    }
    if (newPassword.length < 6) {
      SnackbarHelper.showError(context, 'Mật khẩu phải ít nhất 6 ký tự.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await authService.changePasswordService({
        'phone': widget.phone,
        'newPassword': newPassword,
      });

      if (response['success'] == true || response['status'] == 'success') {
        SnackbarHelper.showSuccess(context, "Đặt lại mật khẩu thành công.");
        context.go('/login');
      } else {
        SnackbarHelper.showError(context, response['error'] ?? 'Đặt lại mật khẩu thất bại.');
      }
    } catch (error) {
      SnackbarHelper.showError(context, 'Đã xảy ra lỗi: $error');
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
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(Icons.lock_outline, color: ColorConfig.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ColorConfig.secondary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: ColorConfig.primary),
        //   onPressed: () => context.go('/login'),
        // ),
        title: Text(
          "Đặt lại mật khẩu",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorConfig.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // const SizedBox(height: 10),
            // Icon(Icons.lock_reset, size: 80, color: Colors.teal.shade400),
            const SizedBox(height: 80),
            Text(
              'Đổi mật khẩu cho tài khoản\n${widget.phone}',
              textAlign: TextAlign.center,
              // style: theme.textTheme.titleMedium?.copyWith(
              //   fontWeight: FontWeight.w600,
              //   color: Colors.grey[800],
              // ),
              style: ThemeConfig.appTextStyle(fontSize: 20, color: ColorConfig.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildPasswordField(
              controller: _newPasswordController,
              label: 'Mật khẩu mới',
              obscureText: _obscureNewPass,
              onToggle: () => setState(() => _obscureNewPass = !_obscureNewPass),
            ),
            const SizedBox(height: 15),
            _buildPasswordField(
              controller: _rePasswordController,
              label: 'Nhập lại mật khẩu mới',
              obscureText: _obscureRePass,
              onToggle: () => setState(() => _obscureRePass = !_obscureRePass),
            ),
            const SizedBox(height: 25),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Đặt lại mật khẩu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () => context.go(GlobalRouterConfig.loginOTP),
              child: Text(
                'Quay lại đăng nhập',
                style: ThemeConfig.appTextStyle(color: ColorConfig.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
