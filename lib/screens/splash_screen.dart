// File: splash_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';

import '../helper/snackbar_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final authService = AuthService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  double _progress = 0.0;
  String _loadingMessage = "Chuẩn bị khởi động...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndContinue();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  Future<void> _initPermissionsAndContinue() async {
    await _updateLoadingProgress(0.2, "Kiểm tra quyền truy cập...");
    await _requestPermissions();

    await _updateLoadingProgress(0.5, "...");
    await _initializeNotification();

    await _updateLoadingProgress(0.8, "Đang tải...");
    await _checkToken();

    await _updateLoadingProgress(1.0, "Hoàn tất!");
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _updateLoadingProgress(double progress, String message) async {
    if (mounted) {
      setState(() {
        _progress = progress;
        _loadingMessage = message;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.notification,
      Permission.storage,
      Permission.photos,
    ];

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        await permission.request();
      }
    }
  }

  Future<void> _initializeNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _flutterLocalNotificationsPlugin.initialize(settings);
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final role = prefs.getString('role')?.replaceAll('"', '').trim() ?? '';

    final bool isLogin = token != null && token.isNotEmpty;

    if (!isLogin) {
      // appLog("Loading: $isLogin - $role - $token");
      context.go('/home-customer');
      return;
    }

    final response = await authService.checkTokenService();

    if (response['success'] == true || response['status'] == 'success') {
      switch (role) {
        case 'customer':
          context.go('/home-customer');
          break;
        case 'ktv':
          context.go('/home-technician');
          break;
        case 'admin':
          context.go('/home-admin');
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
              colors: [
                Colors.white,
                Colors.green.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Hiệu ứng nền động
                _buildAnimatedBackground(),

                // Nội dung chính
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo với animation
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
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade700,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade300
                                          .withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'lib/assets/images/zen-hone-circle-logo.png',
                                    height: 100,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Text ZenHome Spa với animation
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
                                    colors: [
                                      Colors.green.shade300,
                                      Colors.green.shade700,
                                    ],
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

                        // Progress bar và loading message
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              // Custom progress bar
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

                              // Loading message với icon
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_progress < 0.8)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.green.shade600,
                                        ),
                                      ),
                                    )
                                  else if (_progress >= 0.99)
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    )
                                  else
                                    Icon(
                                      Icons.refresh,
                                      color: Colors.green.shade400,
                                      size: 20,
                                    ),
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
                  ),
                ),

                // Footer với phiên bản
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

  Widget _buildAnimatedBackground() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 2 * 3.14159),
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return Opacity(
          opacity: 0.3,
          child: CustomPaint(
            painter: WavePainter(
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

// Custom painter cho hiệu ứng sóng nền
class WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 20.0;
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
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}