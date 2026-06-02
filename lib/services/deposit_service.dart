import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/helper/logger_utils.dart';

import '../apis/deposit_api.dart';

class DepositService {
  Future<Map<String, dynamic>> createQR(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(DepositApi.createQr, data);
  }

  Future<Map<String, dynamic>> confirmDeposit(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(DepositApi.confirmDeposit, data);
  }

  Future<Map<String, dynamic>> historyDeposit() async {
    return await ApiMethodsPrivate.getRequest(DepositApi.history);
  }

  Future<Map<String, dynamic>> verifyDeposit(String query) async {
    final String fullUrl = "${DepositApi.verify}?$query";
    // appLog("fullUrl: $fullUrl");
    return await ApiMethodsPrivate.getRequest(fullUrl);
  }

  Future<Map<String, dynamic>> deleteDeposit(String id) async {
    return await ApiMethodsPrivate.deleteRequest("${DepositApi.delete}/$id");
  }
}
