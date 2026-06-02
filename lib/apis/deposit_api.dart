// _routes.dart
import 'package:spa_app/config/app_config.dart';

class DepositApi {
  static const String createQr = '${AppConfig.apiUrlPrivate}/deposit/create-qr';
  static const String confirmDeposit = '${AppConfig.apiUrlPrivate}/deposit/update-status';
  static const String history = '${AppConfig.apiUrlPrivate}/deposit/history';
  static const String delete = '${AppConfig.apiUrlPrivate}/deposit/delete';
  static const String verify = '${AppConfig.apiUrlPrivate}/deposit/verify';
}
