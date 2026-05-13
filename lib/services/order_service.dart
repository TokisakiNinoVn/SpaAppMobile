import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/order_api.dart';

import '../helper/logger_utils.dart';

class OrderService {
  // Future<Map<String, dynamic>> technicianAddService(Map<String, dynamic> data) async {
  //   return await ApiMethodsPrivate.postRequest(ServiceApiRoutes.technicianAddService, data);
  // }
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    // appLog("Data create order: $data");
    return await ApiMethodsPrivate.postRequest(OrderApiRoutes.create, data);
  }

  Future<Map<String, dynamic>> updateStatus(Map<String, dynamic> data) async {
    final response =  await ApiMethodsPrivate.putRequest(OrderApiRoutes.updateStatus, data);
    return response;
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

  // Technician
  Future<Map<String, dynamic>> listRequestOrder() async {
    return await ApiMethodsPrivate.getRequest('${OrderApiRoutes.listRequestOrder}?status=pending&typeOrder=order-now,book&timeRange=2h');
  }

  Future<Map<String, dynamic>> listApprovedBookOrder() async {
    return await ApiMethodsPrivate.getRequest('${OrderApiRoutes.listRequestOrder}?status=approved&typeOrder=book&timeRange=7d');
  }

  Future<Map<String, dynamic>> listFilterOrder(String queryParams) async {
    return await ApiMethodsPrivate.getRequest('${OrderApiRoutes.listRequestOrder}?$queryParams');
  }
}
