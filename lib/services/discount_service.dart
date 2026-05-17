// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/discount_api.dart';
import 'package:spa_app/apis/helper/api_methods_public.dart';

import '../helper/logger_utils.dart';

class DiscountService {
  Future<Map<String, dynamic>> checkDiscountService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      DiscountApi.checkDiscount,
      data,
    );
  }

  Future<Map<String, dynamic>> listAdminDiscount() async {
    return await ApiMethodsPrivate.getRequest(DiscountApi.listDiscount);
  }

  Future<Map<String, dynamic>> listHome() async {
    return await ApiMethodsPublic.getRequest(DiscountApi.listHome);
  }

  Future<Map<String, dynamic>> listPublic() async {
    return await ApiMethodsPublic.getRequest(DiscountApi.listPublic);
  }

  Future<Map<String, dynamic>> createDiscount(Map<String, dynamic> data) async {
    // appLog("Data create: $data");
    return await ApiMethodsPrivate.postRequest('${DiscountApi.createDiscount}', data);
  }

  Future<Map<String, dynamic>> updateDiscount(String id, Map<String, dynamic> data) async {
    // appLog("Data create: $data");
    return await ApiMethodsPrivate.putRequest('${DiscountApi.updateDiscount}/$id', data);
  }

  Future<Map<String, dynamic>> updateIsUseDiscount(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.patchRequest('${DiscountApi.updateDiscount}/$id', data);
  }

  Future<Map<String, dynamic>> changeIsActiveDiscount(String id, Map<String, dynamic> data) async {
    // print("URL PATCH: ${DiscountApi.changeIsActiveDiscount} -$id - ${data}");
    return await ApiMethodsPrivate.patchRequest('${DiscountApi.changeIsActiveDiscount}/$id', data);
  }

  Future<Map<String, dynamic>> deleteDiscount(String id) async {
    return await ApiMethodsPrivate.deleteRequest('${DiscountApi.deleteDiscount}/$id');
  }
}
