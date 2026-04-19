import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/storage/index.dart';

import '../../../helper/snackbar_helper.dart';
import '../../../services/auth_service.dart';

class ConfirmOTPLoginScreen extends StatefulWidget {
  final String phone;
  const ConfirmOTPLoginScreen({Key? key, required this.phone}) : super(key: key);

  @override
  _ConfirmOTPScreenState createState() => _ConfirmOTPScreenState();
}

class _ConfirmOTPScreenState extends State<ConfirmOTPLoginScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isButtonDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  bool isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    startCountdown();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOut
    );
    _animController.forward();
  }

  Future<void> verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join('');
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập đầy đủ mã OTP'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthService().verifyOTPLoginService({
        'phone': widget.phone,
        'otp': otp,
      });

      final prefs = await SharedPreferences.getInstance();

      if (response['token'] != null) {
        await prefs.setString('token', response['token']);
        await prefs.setBool('isLogin', true);
        await prefs.setString('inforUserLogin', jsonEncode(response['data']));
        await prefs.setString('role', jsonEncode(response['data']?['role']));
        await prefs.setString('statusAccount', jsonEncode(response['data']?['status']));
        await prefs.setString('isTechnicianActive', jsonEncode(response['data']?['isTechnicianActive'] ?? false));

        final role = response['data']?['role'];
        if (role == 'customer') {
          await SharedPrefs.saveValue(PrefType.string, "customerProfile", response['data']?['customerProfile']?? {});
          await SharedPrefs.saveValue(PrefType.int, "balance", response['data']?['customerProfile']?['balance'] ?? 0);

          context.go(CustomerRouterConfig.homeCustomer);
        }
      } else {
        SnackBarHelper.showError(
            context, response['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      appLog('Lỗi đăng nhập: $e');
      SnackBarHelper.showError(
          context, "Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void startCountdown() {
    setState(() {
      _countdown = 60;
      _isButtonDisabled = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _isButtonDisabled = false);
      }
      setState(() => _countdown--);
    });
  }

  Future<void> requestOTP() async {
    final phone = widget.phone;
    if (phone.isEmpty) return;

    try {
      final authService = AuthService();
      final response = await authService.getOTPService({'phone': phone, "type": "otp_login", "fcm_token": "", "resend": true});
      print(response);
      if (response['success'] == true || response['status'] == 'success') {
        startCountdown();
        _clearAllFields();
        FocusScope.of(context).requestFocus(_focusNodes[0]);
      } else {
        SnackBarHelper.showError(
            context, response['error'] ?? 'Yêu cầu OTP thất bại.');
      }
    } catch (error) {
      SnackBarHelper.showError(context, 'Đã xảy ra lỗi: $error');
    }
  }

  void _onFieldChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      verifyOTP();
    }
  }

  void _clearAllFields() {
    for (var c in _controllers) {
      c.clear();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var n in _focusNodes) n.dispose();
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button - minimal
                GestureDetector(
                  onTap: () => context.go(GlobalRouterConfig.loginOTP),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Header - clean and simple
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xác thực OTP',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: ColorConfig.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã xác thực đã được gửi tới số',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.phone,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: ColorConfig.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // OTP boxes - minimal design
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return _OTPBox(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      onChanged: (v) => _onFieldChanged(v, index),
                    );
                  }),
                ),

                const SizedBox(height: 48),

                // Confirm button
                isLoading
                    ? Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
                    : GestureDetector(
                  onTap: verifyOTP,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: ColorConfig.primary,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: Text(
                        'Xác nhận',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Resend section - clean divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Chưa nhận được mã?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Resend button - minimalist
                GestureDetector(
                  onTap: _isButtonDisabled ? null : requestOTP,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: _isButtonDisabled
                            ? Colors.grey.shade300
                            : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: _isButtonDisabled
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              value: _countdown / 60,
                              strokeWidth: 2,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Gửi lại sau $_countdown giây',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      )
                          : const Text(
                        'Gửi lại mã OTP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Individual OTP input box - ultra minimalist
class _OTPBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OTPBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  State<_OTPBox> createState() => _OTPBoxState();
}

class _OTPBoxState extends State<_OTPBox> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool filled = widget.controller.text.isNotEmpty;

    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused
            ? Colors.white
            : filled
            ? Colors.grey.shade100
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF1A1A1A)
              : filled
              ? Colors.grey.shade400
              : Colors.grey.shade200,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 2),
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        keyboardType: TextInputType.number,
        maxLength: 1,
        onChanged: (v) {
          setState(() {});
          widget.onChanged(v);
        },
      ),
    );
  }
}