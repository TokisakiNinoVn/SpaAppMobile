import 'package:spa_app/apis/helper/api_methods_private.dart';

import '../apis/information_api.dart';

class InformationService {
  // Bank
  Future<Map<String, dynamic>> addBank(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(InformationApiRoutes.createBank, data);
  }

  Future<Map<String, dynamic>> listAdminBank() async {
    return await ApiMethodsPrivate.getRequest(InformationApiRoutes.listBank);
  }

  Future<Map<String, dynamic>> updateBank(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${InformationApiRoutes.editBank}/$id', data);
  }

  Future<Map<String, dynamic>> deleteBank(String id) async {
    return await ApiMethodsPrivate.deleteRequest('${InformationApiRoutes.deleteBank}/$id');
  }

  //Feature Service
  Future<Map<String, dynamic>> listFeatureService() async {
    return await ApiMethodsPrivate.getRequest(InformationApiRoutes.listFeatureService);
  }

  Future<Map<String, dynamic>> listFeatureServicePublic() async {
    return await ApiMethodsPrivate.getRequest(InformationApiRoutes.listFeatureServicePublic);
  }

  Future<Map<String, dynamic>> updateFeatureService(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${InformationApiRoutes.updateFeatureService}/$id', data);
  }

  // platform-fees
  Future<Map<String, dynamic>> listPlatformFees() async {
    return await ApiMethodsPrivate.getRequest(InformationApiRoutes.listPlatformFees);
  }

  Future<Map<String, dynamic>> updatePlatformFees(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${InformationApiRoutes.updatePlatformFees}/$id', data);
  }

  Future<Map<String, dynamic>> searchPlatformFees(String query) async {
    return await ApiMethodsPrivate.getRequest('${InformationApiRoutes.searchPlatformFees}?type=$query');
  }

  // Information System
  Future<Map<String, dynamic>> getInformationSystem() async {
    return await ApiMethodsPrivate.getRequest(InformationApiRoutes.getInformationSystem);
  }

  Future<Map<String, dynamic>> updateInformationSystem(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest(InformationApiRoutes.updateInformationSystem, data);
  }
}
