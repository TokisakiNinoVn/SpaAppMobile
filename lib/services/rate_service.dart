import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/rate_api.dart';

import '../helper/logger_utils.dart';

class RateService {
  Future<Map<String, dynamic>> createRate(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(RateApiRoutes.create, data);
  }

  Future<Map<String, dynamic>> updateRate(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest("${RateApiRoutes.update}/$id", data);
  }

  Future<Map<String, dynamic>> deleteRate(String id) async {
    return await ApiMethodsPrivate.getRequest("${RateApiRoutes.delete}/${id}");
  }
}
