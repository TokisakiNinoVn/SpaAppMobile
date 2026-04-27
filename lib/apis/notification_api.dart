// user_routes.dart
import '../config/app_config.dart';

class NotificationApiRoutes {
  static const String create = '${AppConfig.apiAdminUrlPrivate}/notification';
  static const String list = '${AppConfig.apiAdminUrlPrivate}/notification';
  static const String details = '${AppConfig.apiAdminUrlPrivate}/notification/details';
  static const String delete = '${AppConfig.apiAdminUrlPrivate}/notification';
}
