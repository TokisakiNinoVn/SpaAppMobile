// File: splash_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../helper/snackbar_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final authService = AuthService();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPermissionsAndContinue();
    });
  }

  Future<void> _initPermissionsAndContinue() async {
    await _requestPermissions();
    await _initializeNotification();
    await _checkToken();
  }

  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.notification,
      Permission.storage, // For Android <= Android 12
      Permission.photos, // For iOS (if needed)
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
    final isLogin = prefs.getString('isLogin');
    final isTechnicianActive = prefs.getString('isTechnicianActive');
    final role = prefs.getString('role')?.replaceAll('"', '').trim() ?? '';

    if (token == null || token.isEmpty) {
      context.go('/login');
      return;
    }

    final response = await authService.checkTokenService();
    // print("ressponse: $response");

    if (response['success'] == true || response['status'] == 'success') {
      if (role == 'admin') {
        context.go('/home-admin');
      } else if (role == 'ktv') {
        final bool isTechnicianActiveResponse = response['data']['isTechnicianActive'];
        // print("isTechnicianActiveResponse: $isTechnicianActiveResponse");
        if ((isTechnicianActive == 'false' || isTechnicianActive == false) &&
            (isTechnicianActiveResponse == 'true' ||
                isTechnicianActiveResponse == true)) {
          SnackbarHelper.showSuccess(context, 'Hồ sơ của bạn đã được phê duyệt, vui lòng đăng nhâp lại!');
          context.go('/login');
        } else {
          context.go('/home-technician');
        }
      } else {
        prefs.remove('token');
        context.go('/login');
      }
    } else {
      prefs.remove('token');
      context.go('/login');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text("Điều kiện response sai")),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
