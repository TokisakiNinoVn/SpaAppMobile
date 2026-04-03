// auth_routes.dart
import 'package:spa_app/config/app_config.dart';

class BannerApiRoutes {
  static const String createAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner';
  static const String updateAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner';
  static const String configNumberAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner/config-number';
  static const String configDisplayAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner/config/display';
  static const String listAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner/list';
  static const String listStatusAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner/status';
  static const String deleteAdminBanner = '${AppConfig.apiAdminUrlPrivate}/banner';


  static const String listBanner = '${AppConfig.apiUrlPublic}/banner/status';
}
