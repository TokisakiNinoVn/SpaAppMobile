// auth_routes.dart
import 'package:spa_app/config/app_config.dart';

class ServiceApiRoutes {
  static const String createService = '${AppConfig.apiUrlPrivate}/service/create';
  static const String updateService = '${AppConfig.apiUrlPrivate}/service/update';
  static const String deleteService = '${AppConfig.apiUrlPrivate}/service/delete';
  static const String addTimePriceService = '${AppConfig.apiUrlPrivate}/service/time-price';
  static const String technicianAddService = '${AppConfig.apiUrlPrivate}/service/add-service';
  static const String listService = '${AppConfig.apiUrlPrivate}/service/list';
  static const String listBaseService = '${AppConfig.apiUrlPrivate}/service/list-base';

}
