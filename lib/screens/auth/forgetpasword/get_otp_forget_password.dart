import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/services/auth_service.dart';
import '../../../helper/snackbar_helper.dart';

// ─────────────────────────────────────────────
//  Trạng thái của quá trình yêu cầu OTP
// ─────────────────────────────────────────────
enum _OtpRequestState {
  idle,         // Chưa làm gì
  preparingFcm, // Đang lấy FCM / APNs token
  requesting,   // Đang gọi verifyPhoneNumber
  countdown,    // Đang đếm ngược cooldown
}

class OTPForgotPasswordScreen extends StatefulWidget {
  const OTPForgotPasswordScreen({super.key});

  @override
  State<OTPForgotPasswordScreen> createState() =>
      _OTPForgotPasswordScreenState();
}

class _OTPForgotPasswordScreenState extends State<OTPForgotPasswordScreen> {
  // ── Controllers ──────────────────────────────
  final TextEditingController _phoneController = TextEditingController();
  Timer? _countdownTimer;
  bool _isExistsPhone = false;

  // ── State ─────────────────────────────────────
  _OtpRequestState _state = _OtpRequestState.idle;
  int _countdown = 0;
  String? _fcmToken;

  // ── Computed ──────────────────────────────────
  bool get _isLoading =>
      _state == _OtpRequestState.preparingFcm ||
          _state == _OtpRequestState.requesting;

  bool get _isButtonDisabled =>
      _isLoading || _state == _OtpRequestState.countdown;

  // ── Lifecycle ─────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initFcmToken();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _showError(String msg) {
    if (!mounted) return;
    SnackBarHelper.showError(context, msg);
  }

  void _showWarning(String msg) {
    if (!mounted) return;
    SnackBarHelper.showWarning(context, msg);
  }

  void _resetToIdle() {
    _safeSetState(() => _state = _OtpRequestState.idle);
  }

  // ── FCM Token ─────────────────────────────────

  Future<void> _initFcmToken() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        appLog('[FCM] User từ chối permission notification');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _fcmToken = token;
        appLog('[FCM] Token OK: ${token.substring(0, 20)}...');
      } else {
        appLog('[FCM] Token null sau khi có permission');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
    } catch (e, st) {
      appLog('[FCM] _initFcmToken lỗi: $e\n$st');
    }
  }

  Future<void> _waitForApnsToken() async {
    const maxRetries = 5;
    const delay = Duration(seconds: 2);
    for (var i = 0; i < maxRetries; i++) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null) {
          appLog('[FCM] APNs token OK');
          return;
        }
      } catch (e) {
        appLog('[FCM] getAPNSToken lỗi lần $i: $e');
      }
      await Future.delayed(delay);
    }
    appLog('[FCM] APNs token vẫn null sau $maxRetries lần thử');
  }

  Future<void> _onTokenRefresh(String newToken) async {
    _fcmToken = newToken;
    appLog('[FCM] Token refresh');
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('token') != null) {
        // await authService.updateFCMToken(newToken);
      }
    } catch (e) {
      appLog('[FCM] _onTokenRefresh lỗi: $e');
    }
  }

  // ── Validation ────────────────────────────────

  String? _validatePhone(String phone) {
    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0';
    }
    return null;
  }

  // ── Countdown ─────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    _safeSetState(() {
      _countdown = 60;
      _state = _OtpRequestState.countdown;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        _safeSetState(() {
          _countdown = 0;
          _state = _OtpRequestState.idle;
        });
        return;
      }
      _safeSetState(() => _countdown--);
    });
  }

  Future<Map<String, dynamic>?> _checkExistsPhone(String phone) async {
    if (phone.isEmpty) return null;

    final response = await AuthService().existsPhoneService(phone);

    final status = response['status'];
    final data = response['data'] ?? {};

    final exists = data['exists'] == true;
    final isDeleted = data['isDelete'] == true;

    _safeSetState(() {
      _isExistsPhone = exists;
    });

    return {
      'status': status,
      'exists': exists,
      'isDeleted': isDeleted,
    };
  }

  // ── OTP Request ───────────────────────────────
  Future<void> _requestOtp() async {
    if (_isButtonDisabled) return;

    final phone = _phoneController.text.trim();

    final result = await _checkExistsPhone(phone);
    if (result == null) return;

    final status = result['status'];
    final exists = result['exists'] == true;
    final isDeleted = result['isDeleted'] == true;

    if (!exists) {
      _showWarning('Số điện thoại chưa được đăng ký tài khoản');
      return;
    }

    if (isDeleted) {
      _showWarning('Tài khoản đã bị xóa trước đó');
      return;
    }

    if (status != 'success') {
      _showWarning('Không thể xác thực tài khoản');
      return;
    }

    final validationError = _validatePhone(phone);
    if (validationError != null) {
      _showWarning(validationError);
      return;
    }

    // ── Bước 1: Kiểm tra APNs trên iOS ──────────
    _safeSetState(() => _state = _OtpRequestState.preparingFcm);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsOk = await _ensureApnsTokenForOtp();
      if (!apnsOk) {
        _resetToIdle();
        return;
      }
    }

    // ── Bước 2: Gọi Firebase ─────────────────────
    _safeSetState(() => _state = _OtpRequestState.requesting);

    await _callVerifyPhoneNumber(phone);
  }

  Future<bool> _ensureApnsTokenForOtp() async {
    try {
      final apns = await FirebaseMessaging.instance
          .getAPNSToken()
          .timeout(const Duration(seconds: 5));

      if (apns != null) return true;

      appLog('[OTP] APNs token null — có thể đang chạy trên simulator');
      _showError(
        'Không thể xác thực thiết bị iOS.\n'
            'Vui lòng chạy trên thiết bị thật hoặc kiểm tra cấu hình APNs.',
      );
      return false;
    } on TimeoutException {
      appLog('[OTP] APNs token timeout');
      _showError('Hết thời gian chờ xác thực thiết bị. Vui lòng thử lại.');
      return false;
    } catch (e, st) {
      appLog('[OTP] _ensureApnsTokenForOtp lỗi: $e\n$st');
      _showError('Lỗi xác thực thiết bị: $e');
      return false;
    }
  }

  Future<void> _callVerifyPhoneNumber(String phone) async {
    String phoneInternational;
    try {
      phoneInternational = FormatHelper.formatPhoneInternational(phone);
    } catch (e) {
      appLog('[OTP] formatPhoneInternational lỗi: $e');
      _showError('Định dạng số điện thoại không hợp lệ.');
      _resetToIdle();
      return;
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneInternational,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          // Forgot password flow không tự đăng nhập — chỉ log
          appLog('[OTP] verificationCompleted (forgot pw — bỏ qua auto sign-in)');
          _resetToIdle();
        },

        verificationFailed: (FirebaseAuthException e) {
          appLog('[OTP] verificationFailed: ${e.code} — ${e.message}');
          _resetToIdle();
          _showError(_mapFirebaseError(e));
        },

        codeSent: (String verificationId, int? resendToken) {
          appLog('[OTP] codeSent — verificationId OK');
          if (!mounted) return;

          _startCountdown();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              SnackBarHelper.showSuccess(
                context,
                'Đã gửi mã OTP đến số điện thoại của bạn',
              );
              context.push(
                '/get-otp/confirm-otp/$phone',
                extra: {
                  'verificationId': verificationId,
                  'resendToken': resendToken,
                },
              );
            } catch (e) {
              appLog('[OTP] context.push lỗi: $e');
              _showError('Không thể mở màn hình xác nhận OTP. Vui lòng thử lại.');
              _resetToIdle();
            }
          });
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          appLog('[OTP] codeAutoRetrievalTimeout');
        },
      );
    } on FirebaseAuthException catch (e) {
      appLog('[OTP] FirebaseAuthException sync: ${e.code}');
      _resetToIdle();
      _showError(_mapFirebaseError(e));
    } on PlatformException catch (e) {
      appLog('[OTP] PlatformException: ${e.code} — ${e.message}');
      _resetToIdle();
      _showError(_mapPlatformError(e));
    } catch (e, st) {
      appLog('[OTP] _callVerifyPhoneNumber unknown: $e\n$st');
      _resetToIdle();
      _showError('Không thể gửi OTP. Vui lòng kiểm tra kết nối và thử lại.');
    }
  }

  // ── Error Mapping ─────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'too-many-requests':
        return 'Bạn đã yêu cầu OTP quá nhiều lần. Vui lòng thử lại sau.';
      case 'invalid-phone-number':
        return 'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại.';
      case 'quota-exceeded':
        return 'Hệ thống OTP đang quá tải. Vui lòng thử lại sau ít phút.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.';
      case 'app-not-authorized':
        return 'Ứng dụng chưa được cấp quyền sử dụng Firebase Auth.';
      case 'missing-client-identifier':
        return 'Lỗi xác thực thiết bị iOS. Vui lòng đảm bảo APNs đã được cấu hình.';
      case 'captcha-check-failed':
        return 'Xác thực reCAPTCHA thất bại. Vui lòng thử lại.';
      default:
        return e.message ?? 'Lỗi không xác định (${e.code}). Vui lòng thử lại.';
    }
  }

  String _mapPlatformError(PlatformException e) {
    if (e.code == 'Error' || e.message?.contains('cancelled') == true) {
      return 'Xác thực bị huỷ. Vui lòng thử lại và không đóng cửa sổ xác thực.';
    }
    return 'Lỗi hệ thống iOS (${e.code}). Vui lòng thử lại.';
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildPhoneInput(),
              const SizedBox(height: 32),
              _buildCtaButton(),
              const SizedBox(height: 20),
              _buildBackToLoginButton(),
              const SizedBox(height: 48),
              _buildSupportSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build Helpers ─────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConfig.primaryBackground,
      elevation: 0,
      title: Row(
        children: [
          InkWell(
            onTap: () {
              try {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.push(GlobalRouterConfig.loginOTP);
                }
              } catch (e) {
                appLog('[NAV] AppBar back lỗi: $e');
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Quên mật khẩu?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: ColorConfig.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhập số điện thoại để nhận mã OTP',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _isButtonDisabled ? null : _requestOtp(),
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText: 'Số điện thoại',
        labelStyle: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.phone_outlined,
          color: Color(0xFF999999),
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: ColorConfig.textPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }

  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonDisabled ? null : _requestOtp,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: ColorConfig.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
        ),
        child: _buildCtaContent(),
      ),
    );
  }

  Widget _buildCtaContent() {
    if (_isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }

    if (_state == _OtpRequestState.countdown) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              value: _countdown / 60,
              strokeWidth: 2,
              backgroundColor: Colors.grey.shade700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Gửi lại sau $_countdown giây',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      );
    }

    return const Text(
      'Lấy mã OTP',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () {
        try {
          context.go('/login');
        } catch (e) {
          appLog('[NAV] go /login lỗi: $e');
        }
      },
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: Color(0xFF666666)),
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
    );
  }

  Widget _buildSupportSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 0.5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Cần hỗ trợ?',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade200, thickness: 0.5)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 6),
            Text(
              AppConfig.emailAppSupport,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }
}