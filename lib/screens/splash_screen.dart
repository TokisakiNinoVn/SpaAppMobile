// File: splash_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final authService = AuthService();
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final isLogin = prefs.getString('isLogin');
    final role = prefs.getString('role');


    if (token == null || isLogin == false) {
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Phiên đăng nhập hết hạn vui lòng đăng nhập lại!")),
      );
      return;
    }

    final response = await authService.checkTokenService();
    if (response['success'] == true || response['status'] == 'success') {
      if (role == 'admin') {
        context.go('/home-admin');
      } else if (role == 'ktv') {
        context.go('/home');
      }
      // else if (role == 'customer') {
      //   context.go('/home-customer');
      // }
      else context.go('/login');
    } else {
      prefs.remove('token');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
