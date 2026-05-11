import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/notification_api.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';

class NotificationService {
  Future<Map<String, dynamic>> createNotificationService( Map<String, dynamic> data) async {
    // appLog("${NotificationApiRoutes.create} - data: ${data}");
    return await ApiMethodsPrivate.postRequest(
      '${NotificationApiRoutes.create}', data
    );
  }

  Future<Map<String, dynamic>> listNotificationService() async {
    return await ApiMethodsPrivate.getRequest(
      '${NotificationApiRoutes.list}'
    );
  }

  Future<Map<String, dynamic>> deleteNotificationService(String id) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${NotificationApiRoutes.delete}/$id'
    );
  }

   Future<Map<String, dynamic>> detailsNotificationService(String id) async {
      return await ApiMethodsPrivate.getRequest(
        '${NotificationApiRoutes.details}/$id'
      );
   }


  // User
  Future<Map<String, dynamic>> listNotificationUserService() async {
    return await ApiMethodsPrivate.getRequest(
        '${NotificationApiRoutes.listUser}'
    );
  }

   Future<Map<String, dynamic>> readNotificationService(String id) async {
      return await ApiMethodsPrivate.putRequest(
        '${NotificationApiRoutes.readUser}/$id', {}
      );
   }

}
