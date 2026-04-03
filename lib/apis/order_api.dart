// user_routes.dart
import '../config/app_config.dart';

class OrderApiRoutes {
  static const String create = '${AppConfig.apiUrlPrivate}/order/create';
  static const String list = '${AppConfig.apiUrlPrivate}/order/list';
  static const String details = '${AppConfig.apiUrlPrivate}/order';
  static const String updateStatus = '${AppConfig.apiUrlPrivate}/order/update-status';
}
