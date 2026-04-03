// file: app_router.dart
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../screens/auth/signup_screen.dart';
import './customer_router.dart';
import './admin_router.dart';

import 'package:spa_app/screens/auth/confirm_otp_login_screen.dart';
import 'package:spa_app/screens/login_screen.dart';
import 'package:spa_app/screens/home_screen.dart';
import 'package:spa_app/screens/splash_screen.dart';

import 'package:spa_app/screens/auth/forgetpasword/confirm_otp_screen.dart';
import 'package:spa_app/screens/auth/login_otp_screen.dart';
import 'package:spa_app/screens/create_technician_screen.dart';
import 'package:spa_app/screens/auth/forgetpasword/get_otp_forget_password.dart';
import 'package:spa_app/screens/otp_confirm_screen.dart';
import 'package:spa_app/screens/quanly/home_quanly_screen.dart';
import 'package:spa_app/screens/register_partner_screen.dart';
import 'package:spa_app/screens/register_screen.dart';
import 'package:spa_app/screens/auth/forgetpasword/reset_password.dart';
import 'package:spa_app/screens/technician/add_technician_screen.dart';
import 'package:spa_app/screens/technician/edit_add_technician.dart';
import 'package:spa_app/screens/technician/home_technician_screen.dart';
import 'package:spa_app/screens/technician/new_order.dart';
import 'package:spa_app/screens/technician/service/technicianupdate_service.dart';
import 'package:spa_app/screens/technician/technician/user_edit_technician.dart';

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
      builder: (context, state) => const LoginScreen()
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen()
    ),
    GoRoute(
      path: '/login-otp',
      builder: (context, state) => LoginOTPScreen(),
      routes: [
        GoRoute(
          path: 'confirm-login-otp/:phone',
          builder: (context, state) {
            final phone = state.pathParameters['phone'];
            return ConfirmOTPLoginScreen(phone: phone ?? '');
          },
        ),
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
      path: '/register-partner',
      builder: (context, state) => const RegisterPartnerScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: '/home-quanly',
      builder: (context, state) => const HomeQuanLyScreen(),
    ),
    GoRoute(
      path: '/home-technician',
      builder: (context, state) => const HomeTechnicianScreen(),
      routes: [
        GoRoute(
          path: 'technician-update-service',
          builder: (context, state) => const TechnicianUpdateService(),
        ),
        GoRoute(
          path: 'add-technician',
          builder: (context, state) => const AddTechnicianScreen(),
        ),

        GoRoute(
          path: 'orders/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return NewOrderScreen(orderId: orderId);
          },
        ),

      ]
    ),
    GoRoute(
      path: '/create-technician',
      builder: (context, state) => const CreateTechnicianScreen(),
    ),

    GoRoute(
      path: '/edit-add-technician',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return EditAddTechnicianScreen(data: data);
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

    ...adminRoutes,
    ...customerRoutes,
  ],
);
