import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';

import '../apis/withdraw_api.dart';

class WithdrawService {
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(WithdrawApi.create, data);
  }

  Future<Map<String, dynamic>> historyWithdraw() async {
    return await ApiMethodsPrivate.getRequest(WithdrawApi.history);
  }

  Future<Map<String, dynamic>> deleteWithdraw(String id) async {
    return await ApiMethodsPrivate.deleteRequest("${WithdrawApi.delete}/$id");
  }
}
