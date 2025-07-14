// auth_routes.dart
import '../config/app_config.dart';

class UserApiRoutes {
  static const String getListUser = '${AppConfig.apiUrlPrivate}/user/list';

  static const String lockOrUnlockUser = '${AppConfig.apiUrlPrivate}/user/toggle-lock';

  static const String detailUser = '${AppConfig.apiUrlPrivate}/user';
  static const String changePasswordUser = '${AppConfig.apiUrlPrivate}/user/change-password';
  static const String deleteUser = '${AppConfig.apiUrlPrivate}/user/';
}
