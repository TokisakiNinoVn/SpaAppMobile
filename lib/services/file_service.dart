import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/file_api.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';

class FileService {
  Future<Map<String, dynamic>> deleteFileService(String id) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${FileApiRoutes.deleteFile}/$id',
    );
  }

  Future<Map<String, dynamic>> deleteFileService2(String id, data) async {
    return await ApiMethodsPrivate.postRequest(
      '${FileApiRoutes.deleteFile}/$id', data,
    );
  }
}
