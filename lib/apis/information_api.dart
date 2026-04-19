// user_routes.dart
import '../config/app_config.dart';

class InformationApiRoutes {
  // Bank
  static const String listBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
  static const String createBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
  static const String editBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
  static const String deleteBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
}
