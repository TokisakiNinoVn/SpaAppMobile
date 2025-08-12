// user_routes.dart
import 'package:spa_app/config/app_config.dart';

class RealtimeApiRoutes {
  static const String realtimeAccountStatus = '${AppConfig.apiWebsocketUrl}/api/private/ws/account-status';
}
