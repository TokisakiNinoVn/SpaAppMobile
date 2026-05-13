import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/auth_api.dart';
import 'package:spa_app/apis/statistical_api.dart';

import '../helper/logger_utils.dart';

class StatisticalService {
  Future<Map<String, dynamic>> getStatisticalData(String queryText) async {
    return await ApiMethodsPrivate.getRequest("${StatisticalApi.statistical}?$queryText");
  }
}
