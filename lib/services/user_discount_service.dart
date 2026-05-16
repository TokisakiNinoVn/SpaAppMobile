// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/user_discount_api.dart';
import 'package:spa_app/helper/logger_utils.dart';

class UserDiscountService {
  Future<Map<String, dynamic>> saveDiscountService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      UserDiscountApi.saveDiscount,
      data, //{"discountCode": "LIXI2026UPDATE"}
    );
  }


  Future<Map<String, dynamic>> listSaveDiscount() async {
    return await ApiMethodsPrivate.getRequest(UserDiscountApi.listSaveDiscount);
  }

  Future<Map<String, dynamic>> deleteDiscount(String id) async {
    return await ApiMethodsPrivate.deleteRequest('${UserDiscountApi.deleteUserDiscount}/$id');
  }

  Future<Map<String, dynamic>> detailSaveDiscount(String id) async {
    return await ApiMethodsPrivate.getRequest("${UserDiscountApi.detailUserDiscount}/$id");
  }
}
