// file: app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:spa_app/screens/login_screen.dart';
import 'package:spa_app/screens/home_screen.dart';
import 'package:spa_app/screens/splash_screen.dart';

import '../screens/admin/home_admin_screen.dart';
import '../screens/admin/technician/edit_technician.dart';
import '../screens/auth/forgetpasword/confirm_otp_screen.dart';
import '../screens/create_technician_screen.dart';
import '../screens/auth/forgetpasword/get_otp_forget_password.dart';
import '../screens/otp_confirm_screen.dart';
import '../screens/quanly/home_quanly_screen.dart';
import '../screens/register_screen.dart';
import '../screens/auth/forgetpasword/reset_password.dart';
import '../screens/technician/home_technician_screen.dart';
import '../screens/technician/technician/user_edit_technician.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
      routes: [

      ]
    ),
    GoRoute(
      path: '/get-otp',
      builder: (context, state) => OTPForgotPasswordScreen(),
      routes: [
        GoRoute(
          path: 'confirm-otp/:phone',
          builder: (context, state) {
            final phone = state.pathParameters['phone'];
            return ConfirmOTPScreen(phone: phone ?? '');
          },
        ),
      ]
    ),
    GoRoute(
      path: '/reset-password/:phone',
      builder: (context, state) {
        final phone = state.pathParameters['phone'];
        return ResetPasswordScreen(phone: phone ?? '');
      },
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
      path: '/home-quanly',
      builder: (context, state) => const HomeQuanLyScreen(),
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
      path: '/edit-technician',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return EditTechnicianScreen(data: data);
      },
    ),
    GoRoute(
      path: '/otp-confirm',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return OtpConfirmScreen(data: data);
      },
    ),

    // KTV - Technician
    GoRoute(
      path: '/user-edit-technician',
      builder: (context, state) => const UserEditTechnicianScreen(),
    ),
  ],
);
