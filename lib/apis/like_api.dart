// user_routes.dart
import '../config/app_config.dart';

class LikeApiRoutes {
  static const String create = '${AppConfig.apiUrlPrivate}/like/create';
  static const String list = '${AppConfig.apiUrlPrivate}/like/list';
  static const String listBase = '${AppConfig.apiUrlPrivate}/like/list-base';
  static const String delete = '${AppConfig.apiUrlPrivate}/like/delete';
}
