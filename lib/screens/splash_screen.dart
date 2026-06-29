import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/fcm_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../storage/index.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _notifPlugin = FlutterLocalNotificationsPlugin();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isAppActive = true;

  double _progress = 0.0;
  String _loadingMessage = "Đang khởi động...";

  _ScreenState _screenState = _ScreenState.loading;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());

    // Kiểm tra trạng thái app khi vào splash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAppActivity();
    });
  }

  // ─── App Activity Check ────────────────────────────────────────────────────

  Future<void> _checkAppActivity() async {
    try {
      final response = await _authService.getAppActiveService();
      appLog('App Active Response: $response');

      if (response['success'] == false) {
        _setMaintenanceState();
        return;
      }

      final isActive = response['data']['isAppActive'] ?? true;

      setState(() {
        _isAppActive = isActive;
      });

      if (!isActive) {
        _setMaintenanceState();
      } else if (_screenState == _ScreenState.maintenance) {
        // Nếu trước đó đang bảo trì mà giờ đã active → quay lại loading
        setState(() => _screenState = _ScreenState.loading);
        _start();
      }
    } catch (e) {
      appLog('Error checking app activity: $e');
      // Nếu lỗi thì coi như active để không chặn user (có thể retry sau)
    }
  }

  void _setMaintenanceState() {
    if (!mounted) return;
    setState(() {
      _screenState = _ScreenState.maintenance;
      _isAppActive = false;
    });
  }

  // ─── Animations ───────────────────────────────────────────────────────────

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _setProgress(double value, String message) async {
    if (!mounted) return;
    setState(() {
      _progress = value;
      _loadingMessage = message;
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup(
        'apple.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _initNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  // ─── Main flow ────────────────────────────────────────────────────────────

  Future<void> _start() async {
    await _setProgress(0.1, "Đang kiểm tra kết nối...");

    final connected = await _hasInternet();
    if (!connected) {
      if (mounted) {
        setState(() => _screenState = _ScreenState.noInternet);
      }
      return;
    }

    await _checkAndNavigate();
  }

  Future<void> _retry() async {
    if (!mounted) return;
    setState(() {
      _screenState = _ScreenState.loading;
      _progress = 0.0;
      _loadingMessage = "Đang khởi động...";
    });
    await _start();
  }

  Future<void> _checkAndNavigate() async {
    await _setProgress(0.2, "Đang kiểm tra trạng thái...");

    // Kiểm tra lại app active trước khi đi xa hơn
    await _checkAppActivity();
    if (!_isAppActive) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLogin = token != null && token.isNotEmpty;

    if (!isLogin) {
      await _setProgress(0.9, "Hoàn tất!");
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) context.go('/home-customer');
      return;
    }

    // Đã đăng nhập
    await _setProgress(0.4, "Đang khởi tạo dịch vụ...");
    await _initNotification();

    await _setProgress(0.6, "Đang lấy thông tin thiết bị...");
    final fcmToken = await FcmHelper.getFCMToken();

    await _setProgress(0.8, "Đang xác thực...");

    final response = await _authService.checkTokenService({
      'fcmToken': fcmToken,
    });

    await _setProgress(1.0, "Hoàn tất!");
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    final success =
        response['success'] == true || response['status'] == 'success';

    if (success) {
      final role = prefs.getString('role')?.replaceAll('"', '').trim() ?? '';
      switch (role) {
        case 'customer':
          context.go('/home-customer');
          break;
        case 'ktv':
          context.go('/home-technician');
          break;
        case 'admin':
          context.go('/home-admin');
          break;
        case 'quanly':
          context.go('/home-quanly');
          break;
        default:
          await SharedPreferencesHelper.logOut();
          context.go('/home-customer');
      }
    } else {
      await SharedPreferencesHelper.logOut();
      context.go('/home-customer');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.green.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                _buildAnimatedBackground(),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _buildCurrentScreen(),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
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

  Widget _buildCurrentScreen() {
    switch (_screenState) {
      case _ScreenState.noInternet:
        return _buildNoInternet();
      case _ScreenState.maintenance:
        return _buildMaintenance();
      default:
        return _buildLoading();
    }
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      key: const ValueKey('loading'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ... (giữ nguyên phần loading cũ của bạn)
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.green.shade400, Colors.green.shade700],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade300.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'lib/assets/images/zen-hone-circle-logo.png',
                    height: 100,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                const Text(
                  'ZenHome Spa',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black12,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade300, Colors.green.shade700],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thư giãn & Tái tạo năng lượng',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade600,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressIcon(),
                    const SizedBox(width: 12),
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenance() {
    return Padding(
      key: const ValueKey('maintenance'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.settings, size: 80, color: ColorConfig.primary),
          ),
          const SizedBox(height: 32),
          Text(
            'Ứng dụng đang được bảo trì',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Ứng dụng đang được bảo trì, không thể sử dụng ứng dụng ngay lúc này.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checkAppActivity,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Kiểm tra',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text(
              'Thoát ứng dụng',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),

          // url hỗ trợ khách hàng
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(AppConfig.urlSupport);

              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            child: Text(
              'Hỗ trợ khách hàng',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // Các widget khác giữ nguyên (_buildNoInternet, _buildProgressIcon, _buildAnimatedBackground...)
  Widget _buildNoInternet() {
    // ... (giữ nguyên code cũ của bạn)
    return Padding(
      key: const ValueKey('no-internet'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
              size: 64,
              color: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cần kết nối mạng',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ứng dụng cần kết nối Internet để hoạt động. '
            'Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Thử lại',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIcon() {
    if (_progress >= 0.99) {
      return Icon(Icons.check_circle, color: Colors.green.shade600, size: 20);
    }
    if (_progress >= 0.8) {
      return Icon(Icons.refresh, color: Colors.green.shade400, size: 20);
    }
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 2 * 3.14159),
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3,
          child: CustomPaint(
            painter: _WavePainter(
              progress: value,
              color: Colors.green.shade200,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

// ─── Enums & Painters ─────────────────────────────────────────────────────────

enum _ScreenState { loading, noInternet, maintenance }

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  const _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 20.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height / 2 + waveHeight * progress);

    for (double x = 0; x <= size.width; x++) {
      final y = waveHeight * (progress + sin(x / waveLength));
      path.lineTo(x, size.height / 2 + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress || old.color != color;
}
