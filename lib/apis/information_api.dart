// user_routes.dart
import '../config/app_config.dart';

class InformationApiRoutes {
  // Bank
  static const String listBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
  static const String createBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
  static const String editBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';
  static const String deleteBank = '${AppConfig.apiAdminUrlPrivate}/information/banks';

  // Feature Service
  static const String listFeatureService = '${AppConfig.apiAdminUrlPrivate}/information/featured-services';
  static const String listFeatureServicePublic = '${AppConfig.apiUrlPublic}/information/featured-services';
  static const String updateFeatureService = '${AppConfig.apiAdminUrlPrivate}/information/featured-services';

  // platform-fees
  static const String listPlatformFees = '${AppConfig.apiAdminUrlPrivate}/information/platform-fees';
  static const String updatePlatformFees = '${AppConfig.apiAdminUrlPrivate}/information/platform-fees';
  static const String searchPlatformFees = '${AppConfig.apiAdminUrlPrivate}/information/platform-fees/search';
}
