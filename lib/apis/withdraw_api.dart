// _routes.dart
import 'package:spa_app/config/app_config.dart';

class WithdrawApi {
  static const String confirmDeposit = '${AppConfig.apiUrlPrivate}/withdraw/update-status';
  static const String delete = '${AppConfig.apiUrlPrivate}/withdraw/delete';

  // Admin
  static const String filter = '${AppConfig.apiAdminUrlPrivate}/withdraw';
  static const String confirmRequest = '${AppConfig.apiAdminUrlPrivate}/withdraw/update-status';
  static const String detailRequestWithdraw = '${AppConfig.apiAdminUrlPrivate}/withdraw';

  // Tech/Customer
  static const String checkFirstWithdraw = '${AppConfig.apiUrlPrivate}/withdraw/check-first';
  static const String create = '${AppConfig.apiUrlPrivate}/withdraw/create-request';
  static const String history = '${AppConfig.apiUrlPrivate}/withdraw/history';

}
