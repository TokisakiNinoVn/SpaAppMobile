import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/service_api.dart';

import '../helper/logger_utils.dart';

class ServiceService {
  Future<Map<String, dynamic>> technicianAddService(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(ServiceApiRoutes.technicianAddService, data);
  }

  Future<Map<String, dynamic>> listService() async {
    return await ApiMethodsPrivate.getRequest(ServiceApiRoutes.listService);
  }

  Future<Map<String, dynamic>> listBaseService() async {
    return await ApiMethodsPrivate.getRequest(ServiceApiRoutes.listBaseService);
  }

  Future<Map<String, dynamic>> addTimePriceService(String serviceId, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(
        '${ServiceApiRoutes.addTimePriceService}/$serviceId', data);
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(ServiceApiRoutes.createService, data);
  }

  Future<Map<String, dynamic>> updateService(String serviceId, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${ServiceApiRoutes.updateService}/$serviceId', data);
  }

  Future<Map<String, dynamic>> deleteService(String serviceId) async {
    return await ApiMethodsPrivate.deleteRequest('${ServiceApiRoutes.deleteService}/$serviceId');
  }
}
