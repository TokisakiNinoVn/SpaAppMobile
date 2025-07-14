import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiMethodsPublic {
  // Base headers for all requests
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Helper method to parse JSON response
  // static Map<String, dynamic> _parseResponse(http.Response response) {
  //   try {
  //     return jsonDecode(response.body);
  //   } catch (e) {
  //     print('Lỗi khi parse JSON: $e');
  //     return {
  //       'status': 'error',
  //       'message': 'Phản hồi từ server không đúng định dạng JSON.',
  //     };
  //   }
  // }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        // Trường hợp là JSON object như mong muốn
        if (statusCode >= 200 && statusCode < 300) {
          return decoded;
        } else {
          return {
            'status': 'error',
            'message': decoded['message'] ?? 'Đã xảy ra lỗi từ server.',
            'statusCode': statusCode,
          };
        }
      } else if (decoded is List) {
        // Trường hợp là JSON array => bọc lại thành object
        return {
          'status': 'success',
          'data': decoded,
          'statusCode': statusCode,
        };
      } else {
        // Dạng dữ liệu không xác định
        return {
          'status': 'error',
          'message': 'Kiểu dữ liệu từ server không hợp lệ.',
          'statusCode': statusCode,
        };
      }
    } catch (e) {
      print('Lỗi khi parse JSON: $e');
      return {
        'status': 'error',
        'message': 'Phản hồi từ server không đúng định dạng JSON.',
        'statusCode': statusCode,
      };
    }
  }


  // Helper method to handle response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> jsonResponse = _parseResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonResponse;
    } else {
      return {
        'status': 'error',
        'message': jsonResponse['message'] ?? 'Lỗi không xác định.',
      };
    }
  }

  // Helper method to handle errors
  static Map<String, dynamic> _handleError(dynamic e) {
    print('API Error: $e');
    return {
      'status': 'error',
      'message': 'Không thể kết nối đến server. Vui lòng thử lại sau - $e',
    };
  }

  // POST request
  static Future<Map<String, dynamic>> postRequest(
      String url, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // GET request
  static Future<Map<String, dynamic>> getRequest(
      String url, {
        Map<String, String>? headers,
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      // Build URL with query parameters if provided
      Uri uri = Uri.parse(url);
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: {..._defaultHeaders, ...?headers},
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> putRequest(
      String url, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> deleteRequest(
      String url, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PATCH request
  static Future<Map<String, dynamic>> patchRequest(
      String url, {
        Map<String, dynamic>? body,
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {..._defaultHeaders, ...?headers},
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }
}