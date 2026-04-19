// user_routes.dart
import '../config/app_config.dart';

class DiscountApi {
  static const String checkDiscount = '${AppConfig.apiUrlPrivate}/discount/check';
  static const String createDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String updateDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String listDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String deleteDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';
  static const String changeIsActiveDiscount = '${AppConfig.apiAdminUrlPrivate}/discount';

  static const String listSaveDiscount = '${AppConfig.apiAdminUrlPrivate}/user-discount/my-discounts';
  static const String saveDiscount = '${AppConfig.apiAdminUrlPrivate}/user-discount/save';
  static const String deleteUserDiscount = '${AppConfig.apiAdminUrlPrivate}/user-discount';
  static const String detailUserDiscount = '${AppConfig.apiAdminUrlPrivate}/user-discount';



}
