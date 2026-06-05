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
import 'package:spa_app/routes/config/customer_router_config.dart';
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
  codeSent,     // OTP đã gửi thành công
  countdown,    // Đang đếm ngược cooldown
  error,        // Có lỗi xảy ra
}

class LoginOTPScreen extends StatefulWidget {
  const LoginOTPScreen({super.key});

  @override
  State<LoginOTPScreen> createState() => _LoginOTPScreenState();
}

class _LoginOTPScreenState extends State<LoginOTPScreen> with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────
  final TextEditingController _phoneController = TextEditingController();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  Timer? _countdownTimer;

  // ── State ─────────────────────────────────────
  _OtpRequestState _state = _OtpRequestState.idle;
  int _countdown = 0;
  String? _fcmToken;
  String? _errorMessage; // Lỗi hiển thị inline (nếu cần)
  bool _isExistsPhone = false;
  bool _isDeleteAccount = false;

  // ── Computed ──────────────────────────────────
  bool get _isLoading =>
      _state == _OtpRequestState.preparingFcm ||
      _state == _OtpRequestState.requesting;

  bool get _isButtonDisabled =>
      _isLoading || _state == _OtpRequestState.countdown;

  // ── Lifecycle ────────────────────────────────
  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Lấy token nền, không block UI
    _initFcmToken();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _countdownTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────

  /// Guard: chỉ gọi setState khi widget còn mounted
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /// Hiển thị snackbar lỗi (safe)
  void _showError(String msg) {
    if (!mounted) return;
    SnackBarHelper.showError(context, msg);
  }

  /// Hiển thị snackbar cảnh báo (safe)
  void _showWarning(String msg) {
    if (!mounted) return;
    SnackBarHelper.showWarning(context, msg);
  }

  /// Reset về trạng thái có thể bấm lại
  void _resetToIdle() {
    _safeSetState(() {
      _state = _OtpRequestState.idle;
      _errorMessage = null;
    });
  }

  // ── FCM Token ────────────────────────────────

  /// Khởi tạo FCM token ở nền khi màn hình load.
  /// Không show lỗi blocking — chỉ log và lưu token nếu thành công.
  Future<void> _initFcmToken() async {
    try {
      // 1. Xin permission (iOS sẽ show dialog, Android 13+ cũng vậy)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        appLog('[FCM] User từ chối permission notification');
        // Không block màn hình, chỉ log — OTP vẫn có thể gửi qua SMS
        return;
      }

      // 2. iOS: đợi APNs token trước khi lấy FCM token
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }

      // 3. Lấy FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _fcmToken = token;
        appLog('[FCM] Token OK: ${token.substring(0, 20)}...');
      } else {
        appLog('[FCM] Token null sau khi có permission');
      }

      // 4. Lắng nghe refresh token
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefresh);
    } catch (e, st) {
      appLog('[FCM] _initFcmToken lỗi: $e\n$st');
      // Không crash app — FCM token là optional khi dùng OTP qua SMS
    }
  }

  /// Chờ APNs token tối đa 10 giây (simulator sẽ không bao giờ có token).
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

  // ── Validation ───────────────────────────────

  /// Trả về thông báo lỗi nếu số điện thoại không hợp lệ, null nếu OK.
  String? _validatePhone(String phone) {
    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^0\d{9}$').hasMatch(phone)) {
      return 'Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0';
    }
    return null;
  }

  // ── Countdown ────────────────────────────────

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

  Future<Map<String, dynamic>?> _checkExistsPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return null;

    final response = await AuthService().existsPhoneService(phone);

    appLog("Response: $response");

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

  // ── OTP Request ──────────────────────────────
  Future<void> _requestOtp() async {
    final result = await _checkExistsPhone();
    if (result == null) return;

    final status = result['status'];
    final exists = result['exists'] == true;
    final isDeleted = result['isDeleted'] == true;

    if (!exists) {
      _showWarning('Số điện thoại chưa được đăng ký');
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

    // Guard: tránh double-tap
    if (_isButtonDisabled) return;

    final phone = _phoneController.text.trim();

    // Validate trước khi làm bất cứ điều gì
    final validationError = _validatePhone(phone);
    if (validationError != null) {
      _showWarning(validationError);
      return;
    }

    // ── Bước 1: Kiểm tra APNs token trên iOS ───
    _safeSetState(() => _state = _OtpRequestState.preparingFcm);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsOk = await _ensureApnsTokenForOtp();
      if (!apnsOk) {
        // Lỗi đã được show bên trong _ensureApnsTokenForOtp
        _resetToIdle();
        return;
      }
    }

    // ── Bước 2: Gọi Firebase verifyPhoneNumber ──
    _safeSetState(() => _state = _OtpRequestState.requesting);

    await _callVerifyPhoneNumber(phone);
  }

  /// Kiểm tra APNs token có sẵn trước khi gửi OTP (iOS only).
  /// Trả về true nếu sẵn sàng, false nếu không thể tiếp tục.
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

  /// Gọi Firebase verifyPhoneNumber và xử lý toàn bộ callback.
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

        // ── Auto-verify (Android / một số iOS) ──
        verificationCompleted: (PhoneAuthCredential credential) async {
          appLog('[OTP] verificationCompleted — auto sign-in');
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            context.go(CustomerRouterConfig.homeCustomer);
          } on FirebaseAuthException catch (e) {
            appLog('[OTP] signInWithCredential lỗi: ${e.code}');
            _showError(_mapFirebaseError(e));
          } catch (e, st) {
            appLog('[OTP] signInWithCredential unknown error: $e\n$st');
            _showError('Đăng nhập tự động thất bại. Vui lòng nhập mã OTP thủ công.');
          } finally {
            _resetToIdle();
          }
        },

        // ── Gửi thất bại ─────────────────────────
        verificationFailed: (FirebaseAuthException e) {
          appLog('[OTP] verificationFailed: ${e.code} — ${e.message}');
          _resetToIdle();
          _showError(_mapFirebaseError(e));
        },

        // ── Gửi thành công ───────────────────────
        codeSent: (String verificationId, int? resendToken) {
          appLog('[OTP] codeSent — verificationId OK');
          if (!mounted) return;

          _startCountdown(); // bắt đầu cooldown trước khi navigate

          // addPostFrameCallback để tránh navigate trong build cycle
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              context.push(
                '${GlobalRouterConfig.confirmLoginOTP}/$phone',
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
          // Không reset state ở đây vì countdown vẫn đang chạy
        },
      );
    } on FirebaseAuthException catch (e) {
      // verifyPhoneNumber() bản thân throw sync FirebaseAuthException (hiếm)
      appLog('[OTP] FirebaseAuthException sync: ${e.code}');
      _resetToIdle();
      _showError(_mapFirebaseError(e));
    } on PlatformException catch (e) {
      // iOS có thể throw PlatformException khi SafariVC bị lỗi
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
        // iOS: reCAPTCHA hoặc APNs chưa cấu hình đúng
        return 'Lỗi xác thực thiết bị iOS. Vui lòng đảm bảo APNs đã được cấu hình.';
      case 'captcha-check-failed':
        return 'Xác thực reCAPTCHA thất bại. Vui lòng thử lại.';
      default:
        return e.message ?? 'Lỗi không xác định (${e.code}). Vui lòng thử lại.';
    }
  }

  String _mapPlatformError(PlatformException e) {
    // iOS SafariViewController bị dismiss / bị lỗi
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
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildPhoneInput(),
                const SizedBox(height: 32),
                _buildCtaButton(),
                const SizedBox(height: 20),
                _buildFooterLinks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build Helpers ─────────────────────────────

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        try {
          context.go(CustomerRouterConfig.homeCustomer);
        } catch (e) {
          appLog('[NAV] back button lỗi: $e');
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.home, size: 18, color: Color(0xFF333333)),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: ColorConfig.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Đăng nhập bằng số điện thoại',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số điện thoại',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: 'Nhập số điện thoại của bạn',
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 15),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ColorConfig.primary, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCtaButton() {
    return GestureDetector(
      onTap: _isButtonDisabled ? null : _requestOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: BoxDecoration(
          color: _isButtonDisabled
              ? const Color(0xFFCCCCCC)
              : ColorConfig.primary,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(child: _buildCtaContent()),
      ),
    );
  }

  Widget _buildCtaContent() {
    if (_isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      );
    }

    if (_state == _OtpRequestState.countdown) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Text(
            'Gửi lại sau $_countdown giây',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const Text(
      'Tiếp tục',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Center(
      child: Column(
        children: [
          TextButton(
            onPressed: () {
              try {
                context.push(GlobalRouterConfig.login);
              } catch (e) {
                appLog('[NAV] push login lỗi: $e');
              }
            },
            child: const Text(
              'Đăng nhập bằng mật khẩu',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              try {
                context.push('/get-otp');
              } catch (e) {
                appLog('[NAV] push get-otp lỗi: $e');
              }
            },
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(color: Color(0xFF999999), fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              try {
                context.push(GlobalRouterConfig.register);
              } catch (e) {
                appLog('[NAV] push register lỗi: $e');
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chưa có tài khoản?',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  'Đăng ký ngay',
                  style: TextStyle(
                    color: ColorConfig.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}