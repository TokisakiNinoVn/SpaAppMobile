// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/user_api.dart';

class UserService {
  Future<Map<String, dynamic>> getAllUserService() async {
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.getListUser}',
    );
  }
  Future<Map<String, dynamic>> getIsAcceptHaveApprovalRequestService() async {
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.getIsAcceptHaveApprovalRequestUser}',
    );
  }

  Future<Map<String, dynamic>> lockOrUnlockUserService(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      '${UserApiRoutes.lockOrUnlockUser}/$id',
      data,
    );
  }

  Future<Map<String, dynamic>> changePasswordUserService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      UserApiRoutes.changePasswordUser,
      data,
    );
  }
  Future<Map<String, dynamic>> changeRoleService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.putRequest(
      UserApiRoutes.changeRole,
      data,
    );
  }

  Future<Map<String, dynamic>> deleteUserService(String id) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${UserApiRoutes.deleteUser}/$id',
    );
  }

  Future<Map<String, dynamic>> loadDetailUserService() async {
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.detailUser}',
    );
  }

  Future<Map<String, dynamic>> changeStatusUserService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      '${UserApiRoutes.changeStatusUser}',
      data,
    );
  }
}
