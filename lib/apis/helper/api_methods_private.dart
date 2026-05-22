import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'dart:io';

import '../../helper/snackbar_helper.dart';
import '../../routes/app_router.dart';
import '../../routes/config/global_router_config.dart';

class ApiMethodsPrivate {

  static String getPlatform() {
    if (Platform.isAndroid) return "android";
    if (Platform.isIOS) return "ios";
    return "unknown";
  }

  // Hàm lấy token từ SharedPreferences
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    return token;
  }


  static Future<void> _handle401() async {
    final context = rootNavigatorKey.currentContext;

    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    await prefs.remove('token');
    // await prefs.remove('isLogin');


    if (context != null) {
      // SnackbarHelper.showError(context, "Phiên đăng nhập của bạn hết hạn, vui lòng đăng nhập lại!");
      context.go(GlobalRouterConfig.loginOTP);
      //
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => LoginScreen(),
      //   ),
      // );
    }
  }

  // Phương thức POST với token
  static Future<Map<String, dynamic>> postRequest(
      String url,
      Map<String, dynamic> body) async {
    try {
      String? token = await getToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'platform': getPlatform(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 401) {
        _handle401();
        return {'status': 'error', 'message': 'Unauthorized'};
      }

      // Xử lý response
      final jsonResponse = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonResponse;
      } else {
        return {
          'status': 'error',
          'message': jsonResponse['message'] ?? 'Unknown error.',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('API Post Error: $e');
      }
      return {
        'status': 'error',
        'message': 'Cannot connect to the server. Please try again later: $e',
      };
    }
  }

  // Phương thức GET với token
  static Future<Map<String, dynamic>> getRequest(String url) async {
    try {
      // Lấy token từ SharedPreferences
      String? token = await getToken();

      // Tạo headers
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'platform': getPlatform(),
      };

      // Gửi request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 401) {
        _handle401();
        return {'status': 'error', 'message': 'Unauthorized'};
      }

      // Xử lý response
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('API GET Error: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Các phương thức PUT
  static Future<Map<String, dynamic>> putRequest(
      String url, Map<String, dynamic> body) async {
    final fullResponse;
    try {
      String? token = await getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 401) {
        _handle401();
        return {'status': 'error', 'message': 'Unauthorized'};
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('API PUT Error: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Các phương thức PATCH
  static Future<Map<String, dynamic>> patchRequest(
      String url, Map<String, dynamic> body) async {
    try {
      String? token = await getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      // appLog("response: $response");

      if (response.statusCode == 401) {
        _handle401();
        return {'status': 'error', 'message': 'Unauthorized'};
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('API PATCH Error: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Các phương thức DELETE
  static Future<Map<String, dynamic>> deleteRequest(String url) async {
    try {
      String? token = await getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 401) {
        _handle401();
        return {'status': 'error', 'message': 'Unauthorized'};
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        appLog('API DELETE Error: $e');
      }
      return {'error': e.toString()};
    }
  }

}
