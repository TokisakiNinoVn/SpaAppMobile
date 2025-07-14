import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/auth_service.dart';

class OtpConfirmScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const OtpConfirmScreen({super.key, required this.data});

  @override
  State<OtpConfirmScreen> createState() => _OtpConfirmScreenState();
}

class _OtpConfirmScreenState extends State<OtpConfirmScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;

  Future<void> verifyOtp() async {
    final smsCode = otpController.text.trim();
    if (smsCode.length != 6) {
      _showSnack("Mã OTP không hợp lệ");
      return;
    }

    setState(() => isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.data['verificationId'],
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // ✅ Gửi yêu cầu đăng ký tài khoản về server
      final response = await AuthService().registerService({
        'phone': widget.data['phone'],
        'password': widget.data['password'],
        'roles': widget.data['role'],
        if (widget.data['role'] == 'quanly') 'fullname': widget.data['fullname'],
      });

      if (response['status'] == 'success') {
        _showSnack("Đăng ký thành công!");
        context.go('/login');
      } else {
        _showSnack(response['message'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      _showSnack("Lỗi xác minh OTP: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Nhập mã OTP đã gửi đến ${widget.data['phone']}'),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mã OTP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : verifyOtp,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Xác nhận"),
            ),
          ],
        ),
      ),
    );
  }
}
