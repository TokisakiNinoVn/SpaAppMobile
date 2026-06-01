// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/user_api.dart';
import 'package:spa_app/helper/logger_utils.dart';

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
    // appLog("Url: ${UserApiRoutes.detailUser}");
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.detailUser}',
    );
  }

  Future<Map<String, dynamic>> getDataUserLoginService() async {
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.mee}',
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

  // Customer - Address
  Future<Map<String, dynamic>> addAddressService(
      Map<String, dynamic> data,
      ) async {
    return await ApiMethodsPrivate.postRequest(
      '${UserApiRoutes.addAddress}',
      data,
    );
  }

  Future<Map<String, dynamic>> updateAddressService(
      String id,
      Map<String, dynamic> data
      ) async {
    appLog("data: $id - $data");
    return await ApiMethodsPrivate.putRequest(
      '${UserApiRoutes.updateAddress}/$id', data
    );
  }

  Future<Map<String, dynamic>> setDefaultAddressService(
      String id, Map<String, dynamic> data
      ) async {
    return await ApiMethodsPrivate.putRequest(
      '${UserApiRoutes.setDefaultAddress}/$id', data
    );
  }

  Future<Map<String, dynamic>> deleteAddressService(
      String id,
      ) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${UserApiRoutes.deleteAddress}/$id'
    );
  }

  Future<Map<String, dynamic>> listAddress() async {
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.listAddress}',
    );
  }

  // Admin
  Future<Map<String, dynamic>> createManagementAccountService(
    Map<String, dynamic> data,
  ) async {
    return await ApiMethodsPrivate.postRequest(
      UserApiRoutes.createManagerAccount,
      data,
    );
  }

  Future<Map<String, dynamic>> getBalanceUserService() async {
    return await ApiMethodsPrivate.getRequest(
        '${UserApiRoutes.balance}'
    );
  }

  // Technician
  Future<Map<String, dynamic>> getStatisticalTechnicianService(String query) async {
    return await ApiMethodsPrivate.getRequest(
      '${UserApiRoutes.statisticalTechnician}?${query}',
    );
  }

  Future<Map<String, dynamic>> accountRecoveryService(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(
      '${UserApiRoutes.accountRecovery}',
      data,
    );
  }
  Future<Map<String, dynamic>> deleteAccountService() async {
    return await ApiMethodsPrivate.putRequest(
      '${UserApiRoutes.deleteAccount}', {}
    );
  }
}
