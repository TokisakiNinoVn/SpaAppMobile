import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/tinhthanh_api.dart';

class TinhThanhService {
  Future<Map<String, dynamic>> getDetailsTinhThanhApiRoutesService() async {
    return await ApiMethodsPublic.getRequest(
      '${TinhThanhApiRoutes.getTinhThanh}',
    );
  }
  Future<Map<String, dynamic>> getDetailsHuyenApiRoutesService(String idProvince) async {
    return await ApiMethodsPublic.getRequest(
      '${TinhThanhApiRoutes.getHuyen}/?idProvince=$idProvince',
    );
  }
  Future<Map<String, dynamic>> getDetailsXaApiRoutesService(String idDistrict) async {
    return await ApiMethodsPublic.getRequest(
      '${TinhThanhApiRoutes.getXa}/?idDistrict=$idDistrict',
    );
  }
}
