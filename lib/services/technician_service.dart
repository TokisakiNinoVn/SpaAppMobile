import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/technician_api.dart';

class TechnicianService {
  Future<Map<String, dynamic>> getDetailsTechnicianService(String id) async {
    return await ApiMethodsPrivate.getRequest(
      '${TechnicianApiRoutes.detailTechnician}/$id',
    );
  }

  // create
  Future<Map<String, dynamic>> createTechnicianService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      TechnicianApiRoutes.createTechnician,
      data,
    );
  }

  // update
  // Future<Map<String, dynamic>> updateTechnicianService(
  //   String id,
  //   Map<String, dynamic> data,
  // ) async {
  //   return await ApiMethodsPrivate.postRequest(
  //     '${TechnicianApiRoutes.updateTechnicianApi}/$id',
  //     data,
  //   );
  // }

  // Future<Map<String, dynamic>> getListTaiXeTechnicianService() async {
  //   return await ApiMethodsPrivate.getRequest(TechnicianApiRoutes.listTaiXeApi);
  // }
  //
  // Future<Map<String, dynamic>> getListDiemNhanService() async {
  //   return await ApiMethodsPrivate.getRequest(
  //     TechnicianApiRoutes.listDiemNhanApi,
  //   );
  // }
  // Future<Map<String, dynamic>> getListXeService() async {
  //   return await ApiMethodsPrivate.getRequest(
  //     TechnicianApiRoutes.listXeApi,
  //   );
  // }
}
