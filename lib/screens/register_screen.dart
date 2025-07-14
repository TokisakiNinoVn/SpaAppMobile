import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/services/auth_service.dart';

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

  String? selectedRole = 'ktv';
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  // Future<void> handleRegister() async {
  //   final phone = phoneController.text.trim();
  //   final password = passwordController.text;
  //   final confirmPassword = confirmPasswordController.text;
  //   final fullname = fullnameController.text.trim();
  //
  //   // Validation
  //   if (phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
  //     _showSnack('Vui lòng nhập đầy đủ thông tin bắt buộc');
  //     return;
  //   }
  //
  //   if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
  //     _showSnack('Số điện thoại phải có đúng 10 chữ số');
  //     return;
  //   }
  //
  //   if (password.length < 6) {
  //     _showSnack('Mật khẩu phải có ít nhất 6 ký tự');
  //     return;
  //   }
  //
  //   if (password != confirmPassword) {
  //     _showSnack('Mật khẩu xác nhận không khớp');
  //     return;
  //   }
  //
  //   if (selectedRole == 'quanly' && fullname.isEmpty) {
  //     _showSnack('Vui lòng nhập họ và tên');
  //     return;
  //   }
  //
  //   setState(() => isLoading = true);
  //
  //   try {
  //     final response = await authService.registerService({
  //       "phone": phone,
  //       "password": password,
  //       "roles": selectedRole,
  //       if (selectedRole == 'quanly') "fullname": fullname,
  //     });
  //     // Chuyển qua màn hình xác nhận otp số điện thoại
  //
  //     if (response['status'] == 'success') {
  //       if(response['isHaveTechnician'] == false) {
  //         final prefs = await SharedPreferences.getInstance();
  //         await prefs.setString('token', response['token']);
  //         _showSnack('Đăng ký tài khoản thành công!');
  //         context.go('/create-technician');
  //       } else {
  //         _showSnack('Đăng ký tài khoản thành công!');
  //       }
  //     } else {
  //       _showSnack(response['message'] ?? 'Đăng ký thất bại');
  //     }
  //
  //   } catch (e) {
  //     _showSnack('Lỗi hệ thống: $e');
  //     print("Lỗi đăng ký: $e");
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }

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

    if (selectedRole == 'quanly' && fullname.isEmpty) {
      _showSnack('Vui lòng nhập họ và tên');
      return;
    }

    setState(() => isLoading = true);

    final fullPhone = '+84${phone.substring(1)}'; // Chuyển 0123 → +84123
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android có thể tự xác minh được
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'too-many-requests') {
            _showSnack('Thiết bị đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.');
          } else if (e.code == 'invalid-phone-number') {
            _showSnack('Số điện thoại không hợp lệ.');
          } else {
            _showSnack('Lỗi gửi OTP: ${e.message}');
            print('Lỗi gửi OTP: ${e.message}');
          }
        },
          codeSent: (verificationId, resendToken) {
          // Chuyển sang màn hình OTP
          context.push('/otp-confirm', extra: {
            'verificationId': verificationId,
            'phone': phone,
            'password': password,
            'fullname': fullname,
            'role': selectedRole,
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Có thể xử lý timeout tại đây nếu cần
        },
      );
    } catch (e) {
      _showSnack('Lỗi gửi OTP: $e');
      print('Lỗi gửi OTP: $e');
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

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRole,
      decoration: InputDecoration(
        labelText: 'Vai trò',
        prefixIcon: const Icon(Icons.person, color: Color(0xFF8B5E3C)),
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
      items: const [
        DropdownMenuItem(
          value: 'quanly',
          child: Text('Quản lý'),
        ),
        DropdownMenuItem(
          value: 'ktv',
          child: Text('Kĩ thuật viên'),
        ),
      ],
      onChanged: (value) {
        setState(() => selectedRole = value);
      },
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
                  'Đăng ký tài khoản',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    color: const Color(0xFF8B5E3C),
                  ),
                ),
                const SizedBox(height: 40),
                _buildDropdown(),
                if (selectedRole == 'quanly') ...[
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: fullnameController,
                    label: 'Họ và tên',
                    icon: Icons.person_outline,
                    inputAction: TextInputAction.done,
                  ),
                ],
                const SizedBox(height: 24),
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
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  icon: Icons.lock_outline,
                  obscure: !showConfirmPassword,
                  suffix: IconButton(
                    icon: Icon(
                      showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF8B5E3C),
                    ),
                    onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                  ),
                  inputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleRegister,
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
                      'Đăng ký',
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Đã có tài khoản? Đăng nhập',
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