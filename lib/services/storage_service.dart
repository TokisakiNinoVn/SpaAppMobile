// file: lib/services/storage_service.dart - file này 
// chứa các hàm liên quan đến việc lưu trữ dữ liệu trên thiết bị, sử dụng shared_preferences để lưu trữ dữ liệu tạm thời.

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Lưu một giá trị chuỗi vào SharedPreferences
  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Lấy một giá trị chuỗi từ SharedPreferences
  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // 
}

