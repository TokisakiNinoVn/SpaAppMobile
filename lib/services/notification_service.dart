// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/notification_api.dart';

class NotificationService {
  Future<Map<String, dynamic>> createNotificationService( Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(
      '${NotificationApiRoutes.create}', data
    );
  }
}
