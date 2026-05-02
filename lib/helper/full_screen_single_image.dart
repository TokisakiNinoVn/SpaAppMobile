import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spa_app/config/color_config.dart';

class FullScreenSingleImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenSingleImageViewer({
    super.key,
    required this.imageUrl,
  });

  @override
  State<FullScreenSingleImageViewer> createState() => _FullScreenSingleImageViewerState();
}

class _FullScreenSingleImageViewerState extends State<FullScreenSingleImageViewer> {
  bool _isDownloading = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> _showNotification() async {
    bool hasPermission = true;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        hasPermission = await Permission.notification.isGranted;
      }
    }

    if (hasPermission) {
      const androidDetails = AndroidNotificationDetails(
        'image_download',
        'Image Download',
        channelDescription: 'Thông báo tải ảnh',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        'Tải ảnh thành công',
        'Ảnh đã được lưu vào thư viện',
        details,
      );
    }
  }

  Future<bool> _requestPhotosPermission() async {
    final status = await Permission.photos.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cần quyền truy cập', style: TextStyle()),
        content: Text(
          'Vui lòng cấp quyền lưu ảnh trong Cài đặt để tải ảnh về máy.',
          style: TextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Mở cài đặt', style: TextStyle(color: const Color(0xFFD4A373))),
          ),
        ],
      ),
    );
  }

  Future<bool> _requestLegacyStoragePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return false;
    }
    return false;
  }

  Future<void> _downloadImage() async {
    setState(() => _isDownloading = true);
    try {
      // Yêu cầu quyền phù hợp với phiên bản Android
      bool permissionGranted;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+
          permissionGranted = await _requestPhotosPermission();
        } else if (androidInfo.version.sdkInt >= 29) {
          // Android 10,11,12
          permissionGranted = await _requestLegacyStoragePermission();
        } else {
          // Android 9 trở xuống
          permissionGranted = await _requestLegacyStoragePermission();
        }
      } else {
        // iOS
        permissionGranted = await _requestPhotosPermission();
      }


      if (!permissionGranted) {
        throw Exception("Không có quyền lưu ảnh");
      }

      // ... phần tải và lưu ảnh giữ nguyên ...
      final response = await Dio().get(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/downloaded_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(response.data);

      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'SpaApp';

      final result = await MediaStore().saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );

      if (result != null) {
        await _showNotification();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Tải ảnh thành công', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFFD4A373),
        ));
      } else {
        throw Exception("Không thể lưu ảnh vào MediaStore");
      }
    } catch (e) {
      debugPrint("🛑 Lỗi tải ảnh: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Lỗi: ${e.toString()}', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              maxScale: 4.0,
              minScale: 1.0,
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4A373)),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 48),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: ColorConfig.primary,
              onPressed: _isDownloading ? null : _downloadImage,
              child: _isDownloading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.download, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
