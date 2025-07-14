import 'package:spa_app/apis/helper/api_methods_public.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/auth_api.dart';

class AuthService {
  Future<Map<String, dynamic>> loginService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.login, body: data);
  }

  Future<Map<String, dynamic>> registerService(data) async {
    return await ApiMethodsPublic.postRequest(AuthApiRoutes.register,
        body: data);
  }

  Future<Map<String, dynamic>> checkTokenService() async {
    return await ApiMethodsPrivate.getRequest(AuthApiRoutes.checkToken);
  }
}
