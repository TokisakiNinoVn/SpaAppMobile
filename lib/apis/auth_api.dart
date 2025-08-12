// auth_routes.dart
import '../config/app_config.dart';

class AuthApiRoutes {
  static const String login = '${AppConfig.apiUrlPublic}/auth/login';
  static const String logout = '${AppConfig.apiUrlPublic}/auth/logout';
  static const String register = '${AppConfig.apiUrlPublic}/auth/register';
  static const String checkToken = '${AppConfig.apiUrlPublic}/auth/me';

  static const String getOTP = '${AppConfig.apiUrlPublic}/auth/get-otp';
  static const String verifyOTP = '${AppConfig.apiUrlPublic}/auth/verify-otp';
  static const String changePassword = '${AppConfig.apiUrlPublic}/auth/change-password';
}
