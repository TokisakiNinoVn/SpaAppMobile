// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/technician_api.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/storage/index.dart';

class TechnicianService {
  Future<Map<String, dynamic>> getDetailsTechnicianService(String id) async {
    return await ApiMethodsPrivate.getRequest(
      '${TechnicianApiRoutes.detailTechnician}/$id',
    );
  }
  Future<Map<String, dynamic>> getDetailsTechnicianForCustomerService(String id) async {
    return await ApiMethodsPrivate.getRequest(
      '${TechnicianApiRoutes.detailTechnicianForCustomer}/$id',
    );
  }

  // create
  Future<Map<String, dynamic>> createTechnicianService(
      Map<String, dynamic> data,
      ) async {
    // final prettyJson = const JsonEncoder.withIndent('  ').convert(data);

    return await ApiMethodsPrivate.postRequest(
      TechnicianApiRoutes.createTechnician,
      data,
    );
  }
  Future<Map<String, dynamic>> addTechnicianService(
      Map<String, dynamic> data,
      ) async {
    // final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
      // print("data request: $prettyJson");
    return await ApiMethodsPrivate.postRequest(
      TechnicianApiRoutes.addTechnician,
      data,
    );
  }

  Future<Map<String, dynamic>> updateTechnicianService(
      String id,
    Map<String, dynamic> data,
  ) async {
    // debugPrint("$id - data update: $data");
    // print("URL: ${TechnicianApiRoutes.updateTechnician}/$id - data update: $data");
    return await ApiMethodsPrivate.putRequest(
      '${TechnicianApiRoutes.updateTechnician}/$id',
      data,
    );
  }

  Future<Map<String, dynamic>> updateLocationTechnicianService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.putRequest(
      '${TechnicianApiRoutes.updateLocationTechnician}',
      data, // data = { "lat": 21.051424667390705, "lng": 105.8258728666784 }
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
  Future<Map<String, dynamic>> getListTechnicianCreateByUser() async {
    return await ApiMethodsPrivate.getRequest(
      TechnicianApiRoutes.listTechnicianCreateByUser
    );
  }

  Future<Map<String, dynamic>> getListTechnicianForCustomer(double? lat, double? lng, String typeOrder) async {
    // print("✅ $lat - $lng");
    bool isLogin = await SharedPrefs.getValue(PrefType.bool, "isLogin") ?? false;
    String fullUrl = "${TechnicianApiRoutes.listTechnicianForCustomer}?lat=${lat}&lng=${lng}&isLogin=$isLogin&typeOrder=$typeOrder";
    appLog("$fullUrl");
    if(isLogin) {
      return await ApiMethodsPublic.getRequest(fullUrl);
    } else {
      return await ApiMethodsPrivate.getRequest(fullUrl);
    }
  }

  Future<Map<String, dynamic>> filterTechnicianByIdProvince(int idProvince) async {
    return await ApiMethodsPrivate.getRequest(
        '${TechnicianApiRoutes.filterTechnician}?idProvince=${idProvince}'
    );
  }
  Future<Map<String, dynamic>> deleteTechnicianCreateByUser(String? id) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${TechnicianApiRoutes.deleteTechnicianCreateByUser}/$id'
    );
  }
}
