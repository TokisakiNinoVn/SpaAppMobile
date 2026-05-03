// user_routes.dart
import 'package:spa_app/config/app_config.dart';

class RateApiRoutes {
  static const String create = '${AppConfig.apiUrlPrivate}/rate/create';
  static const String update = '${AppConfig.apiUrlPrivate}/rate/update';
  static const String delete = '${AppConfig.apiUrlPrivate}/rate/delete';
}
