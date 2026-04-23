import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/order_api.dart';

import '../helper/logger_utils.dart';

class OrderService {
  // Future<Map<String, dynamic>> technicianAddService(Map<String, dynamic> data) async {
  //   return await ApiMethodsPrivate.postRequest(ServiceApiRoutes.technicianAddService, data);
  // }
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    appLog("Data tạo order: $data");
    return await ApiMethodsPrivate.postRequest(OrderApiRoutes.create, data);
  }

  Future<Map<String, dynamic>> updateStatus(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest(OrderApiRoutes.updateStatus, data);
  }

  Future<Map<String, dynamic>> detailOrder(String id) async {
    return await ApiMethodsPrivate.getRequest("${OrderApiRoutes.details}/${id}");
  }

  Future<Map<String, dynamic>> listOrder() async {
    return await ApiMethodsPrivate.getRequest('${OrderApiRoutes.list}');
  }
  //
  // Future<Map<String, dynamic>> deleteService(String serviceId) async {
  //   return await ApiMethodsPrivate.deleteRequest('${ServiceApiRoutes.deleteService}/$serviceId');
  // }
}
