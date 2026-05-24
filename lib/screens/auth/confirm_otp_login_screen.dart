import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/helper/logger_utils.dart';
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

  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  final List<String> _digits = List.filled(6, '');
  bool _isResendDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  bool isLoading = false;
  final FocusNode _hiddenFocusNode = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    startCountdown();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    // Gán listener cho mỗi controller để xử lý thay đổi
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].addListener(() => _onOtpChanged(i));
    }
  }

  void _onOtpChanged(int index) {
    String text = _otpControllers[index].text;

    // Xử lý paste: nếu dài >1 thì phân bố vào các ô
    if (text.length > 1) {
      final List<String> digits = text.split('');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
        _digits[i] = digits[i];
      }
      // Focus ô cuối cùng hoặc unfocus
      FocusScope.of(context).unfocus();
      if (_digits.every((d) => d.isNotEmpty)) verifyOTP();
      setState(() {});
      return;
    }

    // Logic cũ cho nhập từng ký tự
    if (text.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    }
    setState(() {
      for (int i = 0; i < 6; i++) {
        _digits[i] = _otpControllers[i].text;
      }
    });
    if (_digits.every((d) => d.isNotEmpty)) {
      FocusScope.of(context).unfocus();
      verifyOTP();
    }
  }

// Hàm xử lý khi nhấn phím xóa (backspace) trên ô trống
  void _onKey(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        // Xóa ô hiện tại (rỗng) thì focus về ô trước và xóa nó
        _otpControllers[index - 1].clear();

        FocusScope.of(context).requestFocus(
          _otpFocusNodes[index - 1],
        );

        setState(() {
          _digits[index - 1] = '';
          _digits[index] = '';
        });
      }
    }
  }

  void _clearAllFields() {
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].clear();
      _digits[i] = '';
    }
    setState(() {});
    // Focus về ô đầu tiên
    FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
  }

  Future<void> verifyOTP() async {
    if (isLoading) return;
    final otp = _digits.join();
    if (otp.length != 6) {
      SnackBarHelper.showError(context, 'Vui lòng nhập đầy đủ mã OTP');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await AuthService().verifyOTPLoginService({
        'phone': widget.phone,
        'otp': otp,
      });

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );
    } catch (e) {
      appLog('Lỗi đăng nhập: $e');
      SnackBarHelper.showError(
        context,
        'Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!',
      );
      // Reset OTP khi lỗi để nhập lại
      _clearAllFields();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdown = 60;
      _isResendDisabled = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _isResendDisabled = false;
          _countdown = 0;
        });
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> requestOTP() async {
    if (_isResendDisabled || isLoading) return;
    try {
      final response = await AuthService().getOTPService({
        'phone': widget.phone,
        'type': 'otp_login',
        'fcm_token': '',
        'resend': true,
      });
      if (response['success'] == true || response['status'] == 'success') {
        startCountdown();
        _clearAllFields();
        // Tự động mở keyboard sau khi reset
        Future.delayed(const Duration(milliseconds: 100), () {
          _hiddenFocusNode.requestFocus();
        });
      } else {
        SnackBarHelper.showError(
          context,
          response['error'] ?? 'Yêu cầu OTP thất bại.',
        );
      }
    } catch (error) {
      SnackBarHelper.showError(context, 'Đã xảy ra lỗi: $error');
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].dispose();
      _otpFocusNodes[i].dispose();
    }
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
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

                  // Header
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
                      Icon(Icons.phone_android, size: 16, color: Colors.grey.shade500),
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

                  const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: Focus(
                          onKey: (node, event) {
                            _onKey(event, index);
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _otpFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _otpFocusNodes[index].hasFocus
                                  ? Colors.white
                                  : (_otpControllers[index].text.isNotEmpty
                                  ? Colors.grey.shade100
                                  : const Color(0xFFF8F8F8)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _otpFocusNodes[index].hasFocus
                                      ? const Color(0xFF1A1A1A)
                                      : (_otpControllers[index].text.isNotEmpty
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade200),
                                  width: _otpFocusNodes[index].hasFocus ? 1.5 : 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _otpControllers[index].text.isNotEmpty
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                            onChanged: (_) => _onOtpChanged(index),
                          ),
                        ),
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
                  : // Confirm button (luôn hiển thị, loading bên trong)
                  GestureDetector(
                    onTap: isLoading ? null : verifyOTP,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        color: (_digits.every((d) => d.isNotEmpty) && !isLoading)
                            ? ColorConfig.primary
                            : ColorConfig.primary.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
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

                  // Divider "Chưa nhận được mã?"
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Chưa nhận được mã?',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 0.5)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Resend button
                  GestureDetector(
                    onTap: _isResendDisabled ? null : requestOTP,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: _isResendDisabled
                              ? Colors.grey.shade300
                              : Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: _isResendDisabled
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
      ),
    );
  }
}

// ─── Blinking cursor khi ô đang focus ────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 1.5,
        height: 24,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}