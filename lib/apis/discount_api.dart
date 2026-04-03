// user_routes.dart
import '../config/app_config.dart';

class DiscountApi {
  static const String checkDiscount = '${AppConfig.apiUrlPrivate}/discount/check';

  static const String createDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String updateDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String listDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String deleteDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';

  static const String changeIsActiveDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';

}
