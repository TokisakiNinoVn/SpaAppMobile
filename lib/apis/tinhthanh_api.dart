// auth_routes.dart
import 'package:spa_app/config/app_config.dart';

class TinhThanhApiRoutes {
  static const String getTinhThanh = '${AppConfig.apiUrlTinhThanh}/province';
  static const String getHuyen = '${AppConfig.apiUrlTinhThanh}/district';
  static const String getXa = '${AppConfig.apiUrlTinhThanh}/commune';
}
