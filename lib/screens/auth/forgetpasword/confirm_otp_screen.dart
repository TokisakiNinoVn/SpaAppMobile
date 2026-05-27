import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../helper/snackbar_helper.dart';
import '../../../services/auth_service.dart';

class ConfirmOTPScreen extends StatefulWidget {
  final String phone;
  const ConfirmOTPScreen({Key? key, required this.phone}) : super(key: key);

  @override
  _ConfirmOTPScreenState createState() => _ConfirmOTPScreenState();
}

class _ConfirmOTPScreenState extends State<ConfirmOTPScreen>
    with SingleTickerProviderStateMixin {

  // ─── iOS: single hidden TextField approach ───────────────────────────────
  final TextEditingController _hiddenController = TextEditingController();
  final FocusNode _hiddenFocusNode = FocusNode();

  // ─── Android: 6 TextFields riêng lẻ ────────────────────────────────────
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // ─── Shared state ────────────────────────────────────────────────────────
  final List<String> _digits = List.filled(6, '');
  bool _isResendDisabled = false;
  int _countdown = 0;
  Timer? _timer;
  bool isLoading = false;
  bool _isIOS = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _detectPlatform();
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
  }

  Future<void> _detectPlatform() async {
    if (Platform.isIOS) {
      final deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      setState(() => _isIOS = true);
      _setupIOS();
    } else {
      _setupAndroid();
    }
  }

  // ─── iOS Setup ───────────────────────────────────────────────────────────

  void _setupIOS() {
    _hiddenController.addListener(_onHiddenControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hiddenFocusNode.requestFocus();
    });
  }

  void _onHiddenControllerChanged() {
    if (!_isIOS) return;
    final raw = _hiddenController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (raw.length > 6) {
      _hiddenController.removeListener(_onHiddenControllerChanged);
      _hiddenController.text = raw.substring(0, 6);
      _hiddenController.selection = TextSelection.collapsed(offset: 6);
      _hiddenController.addListener(_onHiddenControllerChanged);
    }

    final clamped = raw.length > 6 ? raw.substring(0, 6) : raw;

    setState(() {
      for (int i = 0; i < 6; i++) {
        _digits[i] = i < clamped.length ? clamped[i] : '';
      }
    });

    if (clamped.length == 6 && !isLoading) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _digits.every((d) => d.isNotEmpty)) {
          verifyOTP();
        }
      });
    }
  }

  // ─── Android Setup ───────────────────────────────────────────────────────

  void _setupAndroid() {
    for (int i = 0; i < 6; i++) {
      final index = i;
      _otpControllers[index].addListener(() => _onAndroidOtpChanged(index));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocusNodes[0].requestFocus();
    });
  }

  void _onAndroidOtpChanged(int index) {
    if (_isIOS) return;
    final text = _otpControllers[index].text;

    if (text.length > 1) {
      final digits = text.replaceAll(RegExp(r'[^0-9]'), '').split('');
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].text = i < digits.length ? digits[i] : '';
        _digits[i] = _otpControllers[i].text;
      }
      FocusScope.of(context).unfocus();
      setState(() {});
      if (_digits.every((d) => d.isNotEmpty) && !isLoading) verifyOTP();
      return;
    }

    if (text.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
    }

    setState(() {
      for (int i = 0; i < 6; i++) {
        _digits[i] = _otpControllers[i].text;
      }
    });

    if (_digits.every((d) => d.isNotEmpty) && !isLoading) {
      FocusScope.of(context).unfocus();
      verifyOTP();
    }
  }

  void _onAndroidKey(RawKeyEvent event, int index) {
    if (_isIOS) return;
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpControllers[index - 1].clear();
        FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
        setState(() {
          _digits[index - 1] = '';
        });
      }
    }
  }

  // ─── Shared Helpers ──────────────────────────────────────────────────────

  void _clearAllFields() {
    if (_isIOS) {
      _hiddenController.removeListener(_onHiddenControllerChanged);
      _hiddenController.clear();
      _hiddenController.addListener(_onHiddenControllerChanged);
    } else {
      for (int i = 0; i < 6; i++) {
        _otpControllers[i].clear();
      }
    }
    setState(() {
      for (int i = 0; i < 6; i++) _digits[i] = '';
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_isIOS) {
        _hiddenFocusNode.requestFocus();
      } else {
        _otpFocusNodes[0].requestFocus();
      }
    });
  }

  // ─── OTP Verify ─────────────────────────────────────────────────────────

  Future<void> verifyOTP() async {
    if (isLoading) return;
    final otp = _digits.join();

    if (otp.length != 6 || _digits.any((d) => d.isEmpty)) {
      SnackBarHelper.showError(context, 'Vui lòng nhập đầy đủ mã OTP');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await AuthService().verifyOTPService({
        'phone': widget.phone,
        'otp': otp,
      });

      if (response['success'] == true || response['status'] == 'success') {
        if (mounted) {
          context.push('/reset-password/${widget.phone}');
        }
      } else {
        SnackBarHelper.showError(
          context,
          response['message'] ?? response['error'] ?? 'Xác minh thất bại',
        );
        _clearAllFields();
      }
    } catch (e) {
      appLog('Lỗi xác thực OTP: $e');
      SnackBarHelper.showError(
        context,
        'Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!',
      );
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
        'type': 'otp_forgot_password',
        'fcm_token': '',
        'resend': true,
      });
      if (response['success'] == true || response['status'] == 'success') {
        startCountdown();
        _clearAllFields();
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
    _hiddenController.dispose();
    _hiddenFocusNode.dispose();
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].dispose();
      _otpFocusNodes[i].dispose();
    }
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ─── Build ───────────────────────────────────────────────────────────────

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
                  GestureDetector(
                    onTap: () => context.go(GlobalRouterConfig.getOptForgotPassword),
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

                  // OTP input row (platform-specific)
                  _isIOS ? _buildIOSOTPRow() : _buildAndroidOTPRow(),

                  const SizedBox(height: 48),

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
                    onTap: isLoading ? null : () {
                      FocusScope.of(context).unfocus();
                      verifyOTP();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        color: (_digits.every((d) => d.isNotEmpty) && !isLoading)
                            ? ColorConfig.primary
                            : ColorConfig.primary.withOpacity(0.5),
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

  // ─── iOS OTP Row ─────────────────────────────────────────────────────────
  Widget _buildIOSOTPRow() {
    return GestureDetector(
      onTap: () => _hiddenFocusNode.requestFocus(),
      child: Stack(
        children: [
          Positioned(
            left: -300,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _hiddenController,
                focusNode: _hiddenFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(border: InputBorder.none),
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
                showCursor: false,
                autofocus: true,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final isFilled = _digits[index].isNotEmpty;
              final filledCount = _digits.where((d) => d.isNotEmpty).length;
              final isActive = index == filledCount && _hiddenFocusNode.hasFocus;

              return _IOSOTPBox(
                digit: _digits[index],
                isActive: isActive,
                isFilled: isFilled,
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Android OTP Row ─────────────────────────────────────────────────────
  Widget _buildAndroidOTPRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: Focus(
            onKey: (node, event) {
              _onAndroidKey(event, index);
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
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
              onChanged: (_) => _onAndroidOtpChanged(index),
            ),
          ),
        );
      }),
    );
  }
}

// ─── iOS OTP Box ─────────────────────────────────────────────────────────────
class _IOSOTPBox extends StatelessWidget {
  final String digit;
  final bool isActive;
  final bool isFilled;

  const _IOSOTPBox({
    required this.digit,
    required this.isActive,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : (isFilled ? Colors.grey.shade100 : const Color(0xFFF8F8F8)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? const Color(0xFF1A1A1A)
              : (isFilled ? Colors.grey.shade400 : Colors.grey.shade200),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: digit.isNotEmpty
            ? Text(
          digit,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        )
            : (isActive ? const _BlinkingCursor() : const SizedBox.shrink()),
      ),
    );
  }
}

// ─── Blinking Cursor ──────────────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

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