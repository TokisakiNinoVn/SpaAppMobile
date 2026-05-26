import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

class ImageDownloadUtil {
  static final FlutterLocalNotificationsPlugin
  _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// =========================
  /// INIT NOTIFICATIONS
  /// =========================
  static Future<void> initializeNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // Android 13+ cần notification permission
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        await Permission.notification.request();
      }
    }
  }

  /// =========================
  /// REQUEST PHOTO PERMISSION
  /// =========================
  static Future<bool> _requestPhotoPermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photosAddOnly.request();
        return status.isGranted;
      }

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Android 13+
        if (androidInfo.version.sdkInt >= 33) {
          return true;
        }

        // Android <= 12
        final status = await Permission.storage.request();
        return status.isGranted;
      }

      return false;
    } catch (e) {
      appLog("🛑 Permission Error: $e");
      return false;
    }
  }

  /// =========================
  /// SHOW SUCCESS NOTIFICATION
  /// =========================
  static Future<void> _showSuccessNotification() async {
    bool hasPermission = true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        hasPermission = await Permission.notification.isGranted;
      }
    }

    if (!hasPermission) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'image_download_channel',
      'Image Download',
      channelDescription: 'Notifications for image downloads',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      0,
      'Tải ảnh thành công',
      'Ảnh đã được lưu vào thư viện',
      details,
    );
  }

  /// =========================
  /// DOWNLOAD IMAGE
  /// =========================
  static Future<bool> downloadImage({
    required String imageUrl,
    BuildContext? context,
    Function(bool)? onComplete,
  }) async {
    try {
      // ===== REQUEST PERMISSION =====
      final hasPermission = await _requestPhotoPermission();

      if (!hasPermission) {
        throw Exception("Không có quyền lưu ảnh");
      }

      // ===== DOWNLOAD IMAGE =====
      final response = await Dio().get(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      final Uint8List bytes =
      Uint8List.fromList(response.data);

      // ===== CREATE TEMP FILE =====
      final tempDir = await getTemporaryDirectory();

      final fileName =
          "spa_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final tempFile = File("${tempDir.path}/$fileName");

      await tempFile.writeAsBytes(bytes);

      // ===== SAVE TO GALLERY =====
      final result = await GallerySaver.saveImage(
        tempFile.path,
        albumName: "Zen Home Spa",
      );

      if (result == true) {
        await _showSuccessNotification();

        if (context != null && context.mounted) {
          SnackBarHelper.showSuccess(
            context,
            "Tải ảnh thành công vào thư viện",
          );
        }

        onComplete?.call(true);

        return true;
      }

      throw Exception("Không thể lưu ảnh");
    } catch (e) {
      appLog("🛑 Download Image Error: $e");

      if (context != null && context.mounted) {
        SnackBarHelper.showError(
          context,
          "Lỗi khi lưu ảnh: ${e.toString()}",
        );
      }

      onComplete?.call(false);
      return false;
    }
  }
}