// user_routes.dart
import '../config/app_config.dart';

class UserApiRoutes {
  static const String getListUser = '${AppConfig.apiUrlPrivate}/user/list';

  static const String lockOrUnlockUser = '${AppConfig.apiUrlPrivate}/user/toggle-lock';

  static const String detailUser = '${AppConfig.apiUrlPrivate}/user/me';
  static const String changePasswordUser = '${AppConfig.apiUrlPrivate}/user/change-password';
  static const String deleteUser = '${AppConfig.apiUrlPrivate}/user';
  static const String changeStatusUser = '${AppConfig.apiUrlPrivate}/user/change-status';
  static const String getIsAcceptHaveApprovalRequestUser = '${AppConfig.apiUrlPrivate}/user/is-accept-have-approval-request';
}
