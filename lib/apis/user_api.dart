// user_routes.dart
import '../config/app_config.dart';

class UserApiRoutes {
  static const String getListUser = '${AppConfig.apiUrlPrivate}/user/list';
  static const String changeRole = '${AppConfig.apiUrlPrivate}/user/change-role';

  static const String lockOrUnlockUser = '${AppConfig.apiUrlPrivate}/user/toggle-lock';

  static const String detailUser = '${AppConfig.apiUrlPrivate}/user/me';
  static const String changePasswordUser = '${AppConfig.apiUrlPrivate}/user/change-password';
  static const String deleteUser = '${AppConfig.apiUrlPrivate}/user';
  static const String changeStatusUser = '${AppConfig.apiUrlPrivate}/user/change-status';
  static const String getIsAcceptHaveApprovalRequestUser = '${AppConfig.apiUrlPrivate}/user/is-accept-have-approval-request';

  static const String mee = '${AppConfig.apiUrlPrivate}/user-app/me';

  static const String addAddress = '${AppConfig.apiUrlPrivate}/user-app/add-address';
  static const String updateAddress = '${AppConfig.apiUrlPrivate}/user-app/update-address';
  static const String deleteAddress = '${AppConfig.apiUrlPrivate}/user-app/delete-address';
  static const String listAddress = '${AppConfig.apiUrlPrivate}/user-app/addresses';
  static const String setDefaultAddress = '${AppConfig.apiUrlPrivate}/user-app/set-default-address';

  // Admin
  static const String createManagerAccount = '${AppConfig.apiUrlPrivate}/user/create-manager-account';

  // Technician/Customer
  static const String balance = '${AppConfig.apiUrlPrivate}/user-app/balance';

}
