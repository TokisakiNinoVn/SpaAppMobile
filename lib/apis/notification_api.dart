// user_routes.dart
import '../config/app_config.dart';

class NotificationApiRoutes {
  static const String create = '${AppConfig.apiUrlPrivate}/notification/create-notification';
  static const String list = '${AppConfig.apiUrlPrivate}/notification';
  static const String details = '${AppConfig.apiUrlPrivate}/notification/details';
  static const String delete = '${AppConfig.apiUrlPrivate}/notification';
}
