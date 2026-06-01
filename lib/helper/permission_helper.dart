// lib/helpers/permission_helper.dart

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Quyền thông báo
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Quyền lưu ảnh
  static Future<bool> requestPhotoPermission() async {
    if (Platform.isIOS) {
      // iOS chỉ cần quyền thêm ảnh
      final status = await Permission.photosAddOnly.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      // Android 13+ không cần storage permission
      if (androidInfo.version.sdkInt >= 33) {
        return true;
      }

      final status = await Permission.storage.request();
      return status.isGranted;
    }

    return false;
  }

  ///Quyền vị trí
  ///

  /// Request các permission khởi tạo app
  static Future<void> requestStartupPermissions() async {
    await requestNotificationPermission();
  }
}