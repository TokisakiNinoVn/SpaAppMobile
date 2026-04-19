// user_routes.dart
import '../config/app_config.dart';

class UserDiscountApi {
  static const String listSaveDiscount = '${AppConfig.apiUrlPrivate}/user-discount/my-discounts';
  static const String saveDiscount = '${AppConfig.apiUrlPrivate}/user-discount/save';
  static const String deleteUserDiscount = '${AppConfig.apiUrlPrivate}/user-discount';
  static const String detailUserDiscount = '${AppConfig.apiUrlPrivate}/user-discount';
}
