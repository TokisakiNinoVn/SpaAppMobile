// user_routes.dart
import '../config/app_config.dart';

class NotificationApiRoutes {
  static const String create = '${AppConfig.apiAdminUrlPrivate}/notification';
  static const String list = '${AppConfig.apiAdminUrlPrivate}/notification';
  static const String details = '${AppConfig.apiAdminUrlPrivate}/notification/details';
  static const String delete = '${AppConfig.apiAdminUrlPrivate}/notification';


  // Notification User
  static const String listUser = '${AppConfig.apiUrlPrivate}/notification-user';
  static const String deleteUser = '${AppConfig.apiUrlPrivate}/notification-user';
  static const String readUser = '${AppConfig.apiUrlPrivate}/notification-user/read';
}
