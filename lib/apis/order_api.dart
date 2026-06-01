// user_routes.dart
import '../config/app_config.dart';

class OrderApiRoutes {
  static const String create = '${AppConfig.apiUrlPrivate}/order/create-v2';
  static const String adminCreate = '${AppConfig.apiUrlPrivate}/order/create-v2';
  static const String list = '${AppConfig.apiUrlPrivate}/order/list';
  static const String details = '${AppConfig.apiUrlPrivate}/order';
  static const String updateStatus = '${AppConfig.apiUrlPrivate}/order/update-status';

  // Admin
  static const String listPostAdmin = '${AppConfig.apiAdminUrlPrivate}/order/list-post';
  static const String listTechnicianApplyPost = '${AppConfig.apiAdminUrlPrivate}/order/technician-apply';

  //Technician
  static const String listRequestOrder = '${AppConfig.apiUrlPrivate}/order';
  static const String applyOrder = '${AppConfig.apiUrlPrivate}/order/apply-order';
  static const String currentWorking = '${AppConfig.apiUrlPrivate}/order/current-working-order';
}
