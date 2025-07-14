// auth_routes.dart
import '../config/app_config.dart';

class AuthApiRoutes {
  static const String login = '${AppConfig.apiUrlPublic}/auth/login';
  static const String register = '${AppConfig.apiUrlPublic}/auth/register';
  static const String checkToken = '${AppConfig.apiUrlPublic}/auth/me';
}
