import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/upload_api.dart';

class UploadService {
  Future<Map<String, dynamic>> uploadSingleFileService(
      String filePath,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final uri = Uri.parse(UploadApiRoutes.singleFile);
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
    }

    if (filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Lỗi khi tải lên tệp: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> uploadManyFilesService(
      List<String> filePaths,
      ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final uri = Uri.parse(UploadApiRoutes.multiFiles);
    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
    }

    for (var path in filePaths) {
      if (path.isNotEmpty && File(path).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('files', path),
        );
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Lỗi khi tải lên nhiều tệp: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
