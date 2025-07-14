import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiMethodsPrivate {
  // Hàm lấy token từ SharedPreferences
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    // if (token != null) {
    //   if (kDebugMode) {
    //     print("Token from SharedPreferences: $token");
    //   }
    // } else {
    //   if (kDebugMode) {
    //     print("Token not found in SharedPreferences");
    //   }
    // }
    return token;
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
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      // Xử lý response
      final jsonResponse = jsonDecode(response.body);
      // print(jsonResponse);
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
        print('API Post Error: $e');
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
      };

      // Gửi request
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      // Xử lý response
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('API GET Error: $e');
      }
      return {'error': e.toString()};
    }
  }

  // Các phương thức PUT
  static Future<Map<String, dynamic>> putRequest(
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('API PUT Error: $e');
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

      if (response.statusCode == 200 || response.statusCode == 204) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('API DELETE Error: $e');
      }
      return {'error': e.toString()};
    }
  }

}
