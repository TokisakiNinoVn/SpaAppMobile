import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';

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
  late Animation<Offset> _slideAnim;

  // Spa palette (matching LoginOTPScreen)
  static const Color creamBg   = Color(0xFFFAF6F1);
  static const Color roseTaupe = Color(0xFF9C7B6E);
  static const Color warmBrown = Color(0xFF6B4C41);
  static const Color softGold  = Color(0xFFBFA07A);
  static const Color mutedSage = Color(0xFF8A9E8C);
  static const Color textDark  = Color(0xFF3A2E2A);
  static const Color inputBg   = Color(0xFFF3EDE7);

  @override
  void initState() {
    super.initState();
    startCountdown();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  Future<void> verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join('');
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập đầy đủ mã OTP.'),
          backgroundColor: roseTaupe,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        await prefs.setString('isTechnicianActive',
            jsonEncode(response['data']?['isTechnicianActive'] ?? false));

        final role = response['data']?['role'];
        if (role == 'customer') {
          await prefs.setString(
              'customerProfile', jsonEncode(response['data']?['customerProfile']));
          context.go('/home-customer');
        }
      } else {
        SnackbarHelper.showError(
            context, response['message'] ?? "Đăng nhập thất bại");
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      SnackbarHelper.showError(
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
        SnackbarHelper.showError(
            context, response['error'] ?? 'Yêu cầu OTP thất bại.');
      }
    } catch (error) {
      SnackbarHelper.showError(context, 'Đã xảy ra lỗi: $error');
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
      backgroundColor: creamBg,
      body: Stack(
        children: [
          // ── Decorative blobs (same language as LoginOTPScreen) ──
          Positioned(
            top: -80, left: -60,
            child: _blob(280, softGold.withOpacity(0.12)),
          ),
          Positioned(
            top: -40, right: -80,
            child: _blob(220, mutedSage.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -60, right: -40,
            child: _blob(200, roseTaupe.withOpacity(0.10)),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back button ──
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => context.go(GlobalRouterConfig.loginOTP),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: softGold.withOpacity(0.4), width: 1),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: warmBrown),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Header ──
                      Center(
                        child: Column(
                          children: [
                            // Icon shield / lock in circle
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: softGold.withOpacity(0.28),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shield_outlined,
                                  size: 36, color: softGold),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Xác thực OTP',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: warmBrown,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                    width: 24, height: 1,
                                    color: softGold.withOpacity(0.6)),
                                const SizedBox(width: 8),
                                const Text(
                                  'Serene Spa',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: roseTaupe,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                    width: 24, height: 1,
                                    color: softGold.withOpacity(0.6)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Card ──
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: warmBrown.withOpacity(0.08),
                              blurRadius: 32,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Info text
                            Text(
                              'Mã xác thực đã được gửi tới',
                              style: TextStyle(
                                fontSize: 14,
                                color: roseTaupe.withOpacity(0.85),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_iphone_outlined,
                                    size: 16, color: softGold),
                                const SizedBox(width: 6),
                                Text(
                                  widget.phone,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: warmBrown,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // ── OTP boxes ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                return _OTPBox(
                                  controller: _controllers[index],
                                  focusNode: _focusNodes[index],
                                  onChanged: (v) => _onFieldChanged(v, index),
                                );
                              }),
                            ),

                            const SizedBox(height: 32),

                            // ── Confirm button ──
                            isLoading
                                ? const SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: roseTaupe, strokeWidth: 2.5),
                              ),
                            )
                                : GestureDetector(
                              onTap: verifyOTP,
                              child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF9C7B6E),
                                      Color(0xFF6B4C41),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: roseTaupe.withOpacity(0.38),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Xác nhận',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Divider ──
                            Row(children: [
                              Expanded(
                                  child: Divider(
                                      color: softGold.withOpacity(0.25),
                                      thickness: 1)),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Chưa nhận được mã?',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: roseTaupe.withOpacity(0.8)),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: softGold.withOpacity(0.25),
                                      thickness: 1)),
                            ]),

                            const SizedBox(height: 16),

                            // ── Resend button ──
                            AnimatedOpacity(
                              opacity: _isButtonDisabled ? 0.55 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: GestureDetector(
                                onTap: _isButtonDisabled ? null : requestOTP,
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: inputBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _isButtonDisabled
                                          ? softGold.withOpacity(0.2)
                                          : softGold.withOpacity(0.55),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: _isButtonDisabled
                                        ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Countdown ring
                                        SizedBox(
                                          width: 18, height: 18,
                                          child: CircularProgressIndicator(
                                            value: _countdown / 60,
                                            strokeWidth: 2,
                                            backgroundColor:
                                            softGold.withOpacity(0.2),
                                            color: softGold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Gửi lại sau $_countdown giây',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: roseTaupe,
                                          ),
                                        ),
                                      ],
                                    )
                                        : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded,
                                            size: 18, color: warmBrown),
                                        SizedBox(width: 8),
                                        Text(
                                          'Gửi lại mã OTP',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: warmBrown,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Bottom brand ──
                      Center(
                        child: Text(
                          '✦  Serene Spa  ✦',
                          style: TextStyle(
                            fontSize: 11,
                            color: softGold.withOpacity(0.55),
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

// ── Individual OTP input box ──────────────────────────────────────────────────
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

  static const Color softGold  = Color(0xFFBFA07A);
  static const Color warmBrown = Color(0xFF6B4C41);
  static const Color inputBg   = Color(0xFFF3EDE7);

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 38,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: _isFocused
            ? Colors.white
            : filled
            ? softGold.withOpacity(0.12)
            : inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused
              ? softGold
              : filled
              ? softGold.withOpacity(0.6)
              : softGold.withOpacity(0.25),
          width: _isFocused ? 2.0 : 1.2,
        ),
        boxShadow: _isFocused
            ? [
          BoxShadow(
            color: softGold.withOpacity(0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
            : [],
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: warmBrown,
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