import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:spa_app/screens/login_screen.dart';
import 'package:spa_app/screens/home_screen.dart';
import 'package:spa_app/screens/splash_screen.dart';

import '../screens/admin/home_admin_screen.dart';
import '../screens/create_technician_screen.dart';
import '../screens/otp_confirm_screen.dart';
import '../screens/register_screen.dart';
import '../screens/technician/home_technician_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/home-admin',
      builder: (context, state) => const HomeAdminScreen(),
    ),
    GoRoute(
      path: '/home-technician',
      builder: (context, state) => const HomeTechnicianScreen(),
    ),
    GoRoute(
      path: '/create-technician',
      builder: (context, state) => const CreateTechnicianScreen(),
    ),
    GoRoute(
      path: '/otp-confirm',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return OtpConfirmScreen(data: data);
      },
    ),
  ],
);
