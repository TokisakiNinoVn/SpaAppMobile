import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';

import '../apis/banner_api.dart';

class BannerService {
  Future<Map<String, dynamic>> addBanner(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(BannerApiRoutes.createAdminBanner, data);
  }

  Future<Map<String, dynamic>> listAdminBanner() async {
    return await ApiMethodsPrivate.getRequest(BannerApiRoutes.listAdminBanner);
  }

  Future<Map<String, dynamic>> listStatusAdminBanner() async {
    return await ApiMethodsPrivate.getRequest(BannerApiRoutes.listStatusAdminBanner);
  }

  Future<Map<String, dynamic>> updateBanner(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${BannerApiRoutes.updateAdminBanner}/$id', data);
  }

  Future<Map<String, dynamic>> configNumberBanner(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${BannerApiRoutes.configNumberAdminBanner}', data);
  }

  Future<Map<String, dynamic>> configDisplayBanner(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.putRequest('${BannerApiRoutes.configDisplayAdminBanner}', data);
  }

  Future<Map<String, dynamic>> deleteBanner(String id) async {
    return await ApiMethodsPrivate.deleteRequest('${BannerApiRoutes.deleteAdminBanner}/$id');
  }


  Future<Map<String, dynamic>> listPublicBanner() async {
    return await ApiMethodsPublic.getRequest(BannerApiRoutes.listBanner);
  }
}
