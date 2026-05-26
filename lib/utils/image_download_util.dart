import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

class ImageDownloadUtil {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Khởi tạo thông báo
  static Future<void> initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          appLog("🛑 Quyền thông báo không được cấp");
        }
      }
    }
  }

  /// Hiển thị thông báo thành công
  static Future<void> _showSuccessNotification(BuildContext? context) async {
    bool hasPermission = true;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        hasPermission = await Permission.notification.isGranted;
      }
    }

    if (hasPermission) {
      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'image_download_channel',
        'Image Download',
        channelDescription: 'Notifications for image downloads',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );
      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        0,
        'Tải ảnh thành công',
        'Ảnh đã được lưu vào thư viện ảnh',
        platformChannelSpecifics,
      );
    } else if (context != null) {
      appLog("🛑 Không có quyền hiển thị thông báo");
      SnackBarHelper.showError(context, "Vui lòng cấp quyền thông báo để nhận thông báo");
    }
  }

  /// Tải và lưu ảnh
  /// Returns: true nếu thành công, false nếu thất bại
  static Future<bool> downloadImage({
    required String imageUrl,
    BuildContext? context,
    Function(bool)? onComplete,
  }) async {
    try {
      PermissionStatus status;

      // ===== REQUEST PERMISSION THEO PLATFORM =====
      if (Platform.isIOS) {
        // iOS chỉ cần quyền thêm ảnh
        status = await Permission.photosAddOnly.request();
      } else if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        // Android 13+
        if (androidInfo.version.sdkInt >= 33) {
          status = PermissionStatus.granted;
        } else {
          // Android <= 12
          status = await Permission.storage.request();
        }
      } else {
        status = PermissionStatus.granted;
      }

      if (!status.isGranted) {
        throw Exception("Không có quyền lưu ảnh");
      }

      // ===== DOWNLOAD IMAGE =====
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final Uint8List bytes = Uint8List.fromList(response.data);

      final tempDir = await getTemporaryDirectory();
      final fileName =
          "image_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final tempFile = File("${tempDir.path}/$fileName");

      await tempFile.writeAsBytes(bytes);

      // ===== SAVE IMAGE =====
      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'SpaApp';

      final mediaStore = MediaStore();

      final result = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );

      if (result != null) {
        await _showSuccessNotification(context);

        if (context != null) {
          SnackBarHelper.showSuccess(
            context,
            "Tải ảnh thành công vào thư viện",
          );
        }

        onComplete?.call(true);
        return true;
      } else {
        throw Exception("Không thể lưu ảnh");
      }
    } catch (e) {
      appLog("🛑 Lỗi lưu ảnh: $e");

      if (context != null) {
        SnackBarHelper.showError(
          context,
          "Lỗi khi lưu ảnh: ${e.toString()}",
        );

        appLog("Lỗi khi lưu ảnh: ${e.toString()}");
      }

      onComplete?.call(false);
      return false;
    }
  }
}