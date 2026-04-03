// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/customer_api.dart';

class CustomerService {
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest(
      '${CustomerApiRoutes.update}', data
    );
  }
  //
  // Future<Map<String, dynamic>> listCustomerService() async {
  //   return await ApiMethodsPrivate.getRequest(
  //     '${LikeApiRoutes.list}'
  //   );
  // }
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
