import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/file_api.dart';

class FileService {
  Future<Map<String, dynamic>> deleteFileService(String id) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${FileApiRoutes.deleteFile}/$id',
    );
  }
}
