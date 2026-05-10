// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/customer_api.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';

class CustomerService {
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    appLog("data: $data");
    return await ApiMethodsPrivate.putRequest(
      '${CustomerApiRoutes.update}', data
    );
  }
  Future<Map<String, dynamic>> balanceCustomerService() async {
    return await ApiMethodsPrivate.getRequest(
      '${CustomerApiRoutes.balanceCustomer}'
    );
  }
  //
  // Future<Map<String, dynamic>> listBaseCustomerService() async {
  //   return await ApiMethodsPrivate.getRequest(
  //     '${LikeApiRoutes.listBase}'
  //   );
  // }
  //
  // Future<Map<String, dynamic>> deleteCustomerService(String likeId) async {
  //   return await ApiMethodsPrivate.deleteRequest(
  //     '${LikeApiRoutes.delete}/$likeId'
  //   );
  // }
}
