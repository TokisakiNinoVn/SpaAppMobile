// import 'dart:convert';
// import 'package:http/http.dart' as http;

import 'package:spa_app/apis/helper/api_methods_private.dart';
import 'package:spa_app/apis/like_api.dart';

class LikeService {
  Future<Map<String, dynamic>> createLikeService(Map<String, dynamic> data) async {
    return await ApiMethodsPrivate.postRequest(
      '${LikeApiRoutes.create}', data
    );
  }

  Future<Map<String, dynamic>> listLikeService() async {
    return await ApiMethodsPrivate.getRequest(
      '${LikeApiRoutes.list}'
    );
  }

  Future<Map<String, dynamic>> listBaseLikeService() async {
    return await ApiMethodsPrivate.getRequest(
      '${LikeApiRoutes.listBase}'
    );
  }

  Future<Map<String, dynamic>> deleteLikeService(String likeId) async {
    return await ApiMethodsPrivate.deleteRequest(
      '${LikeApiRoutes.delete}/$likeId'
    );
  }
}
