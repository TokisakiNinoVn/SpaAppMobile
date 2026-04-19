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

  //Banner

}
