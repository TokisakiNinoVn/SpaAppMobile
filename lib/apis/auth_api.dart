// auth_routes.dart
import 'package:spa_app/config/app_config.dart';

class AuthApiRoutes {
  static const String login = '${AppConfig.apiUrlPublic}/auth/login';
  static const String logout = '${AppConfig.apiUrlPublic}/auth/logout';
  static const String register = '${AppConfig.apiUrlPublic}/auth/register';
  static const String checkToken = '${AppConfig.apiUrlPublic}/auth/me';

  static const String getOTP = '${AppConfig.apiUrlPublic}/auth/get-otp';
  static const String verifyOTP = '${AppConfig.apiUrlPublic}/auth/verify-otp';
  static const String verifyOTPLogin = '${AppConfig.apiUrlPublic}/auth/verify-otp-login';
  static const String changePassword = '${AppConfig.apiUrlPublic}/auth/change-password';

  static const String changeRolePrivate = '${AppConfig.apiUrlPrivate}/auth-private/change-role';

  static const String checkTokenUser = '${AppConfig.apiUrlPrivate}/auth-private/me';
  static const String verifyFirebase = '${AppConfig.apiUrlPublic}/auth/verify-firebase';
  static const String existsPhone = '${AppConfig.apiUrlPublic}/auth/exists-phone';
}
