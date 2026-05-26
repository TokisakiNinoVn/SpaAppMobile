import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/helper/logger_utils.dart';

import '../apis/withdraw_api.dart';

class WithdrawService {
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> data) async {
    // appLog("data: $data");
    return await ApiMethodsPrivate.postRequest(WithdrawApi.create, data);
  }

  Future<Map<String, dynamic>> historyWithdraw() async {
    return await ApiMethodsPrivate.getRequest(WithdrawApi.history);
  }

  Future<Map<String, dynamic>> deleteWithdraw(String id) async {
    return await ApiMethodsPrivate.deleteRequest("${WithdrawApi.delete}/$id");
  }

  // Admin
  Future<Map<String, dynamic>> listRequestWithdraw(String? queryString) async {
    return await ApiMethodsPrivate.getRequest("${WithdrawApi.filter}?$queryString");
  }

  Future<Map<String, dynamic>> confirmRequestWithdraw(data) async {
    appLog("data: $data");
    return await ApiMethodsPrivate.putRequest(WithdrawApi.confirmRequest, data);
  }

  Future<Map<String, dynamic>> detailRequestWithdraw(String id) async {
    return await ApiMethodsPrivate.getRequest("${WithdrawApi.detailRequestWithdraw}/$id");
  }

  //Technician/Customer
  Future<Map<String, dynamic>> hasFirstWithdrawalToday() async {
    // final url =
    appLog("URL: ${WithdrawApi.checkFirstWithdraw}");
    return await ApiMethodsPrivate.getRequest(WithdrawApi.checkFirstWithdraw);
  }
}
