import 'package:spa_app/config/app_config.dart';

class UploadApiRoutes {
  static const String singleFile = '${AppConfig.apiUrlPrivate}/upload/image';
  static const String multiFiles = '${AppConfig.apiUrlPrivate}/upload/images';
}
