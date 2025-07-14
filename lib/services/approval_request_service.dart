import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/approval_request_api.dart';

class ApprovalRequestService {
  Future<Map<String, dynamic>> getAllApprovalRequestService() async {
    return await ApiMethodsPrivate.getRequest(
      '${ApprovalRequestApiRoutes.getAllApprovalRequest}',
    );
  }
  Future<Map<String, dynamic>> approveApprovalRequestService(String id, Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(
      '${ApprovalRequestApiRoutes.getAllApprovalRequest}/$id', data // Data không cần có thông tin gì
    );
  }
}
