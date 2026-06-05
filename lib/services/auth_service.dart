import 'package:http/http.dart';
import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/auth_api.dart';

import '../helper/logger_utils.dart';

class AuthService {
  Future<Map<String, dynamic>> loginService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.login, body: data);
  }
  
  Future<Map<String, dynamic>> verifyFirebaseService(data) async {
    // appLog("Data: $data");
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.verifyFirebase, body: data);
  }

  Future<Map<String, dynamic>> existsPhoneService(String phone) async {
    return await ApiMethodsPublic.getRequest('${AuthApiRoutes.existsPhone}?phone=$phone');
  }

  Future<Map<String, dynamic>> logoutAuthService() async {
    return await ApiMethodsPrivate.postRequest(AuthApiRoutes.logout, {});
  }

  Future<Map<String, dynamic>> getOTPService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.getOTP, body: data);
  }

  Future<Map<String, dynamic>> switchRoleAccount(data) async {
    // appLog("Role: $data");
    return await ApiMethodsPrivate.postRequest(AuthApiRoutes.changeRolePrivate, data);
  }

  Future<Map<String, dynamic>> verifyOTPService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.verifyOTP, body: data);
  }
  Future<Map<String, dynamic>> verifyOTPLoginService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.verifyOTPLogin, body: data);
  }

  Future<Map<String, dynamic>> changePasswordService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.changePassword, body: data);
  }

  Future<Map<String, dynamic>> logoutService(
      Map<String, dynamic> data,
      ) async {
    return await ApiMethodsPrivate.postRequest(
      '${AuthApiRoutes.logout}',
      data,
    );
  }

  Future<Map<String, dynamic>> registerService(data) async {
    return await ApiMethodsPrivate.postRequest(AuthApiRoutes.register, data);
  }

  Future<Map<String, dynamic>> checkTokenService(payload) async {
    return await ApiMethodsPrivate.putRequest(AuthApiRoutes.checkTokenUser, payload);
  }
}
