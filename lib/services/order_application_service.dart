import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/order_application_api.dart';

import '../helper/logger_utils.dart';

class OrderApplicationService {
  // Admin
  Future<Map<String, dynamic>> rejectEntrustOrder(
    Map<String, dynamic> body,
  ) async {
    appLog("Data reject entrust order: $body");
    return await ApiMethodsPrivate.postRequest(
      '${OrderApplicationApi.rejectEntrustOrder}',
      body,
    );
  }
}
