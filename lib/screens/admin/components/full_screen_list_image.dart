import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spa_app/services/approval_request_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';


class FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;
  final String Function(String) formatImageUrl;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.formatImageUrl,
  });

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloading = false;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
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

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.notification.request();
        if (!status.isGranted) {
          debugPrint("🛑 Quyền thông báo không được cấp");
        }
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

      await flutterLocalNotificationsPlugin.show(
        0,
        'Tải ảnh thành công',
        'Ảnh đã được lưu vào thư viện ảnh',
        platformChannelSpecifics,
      );
    } else {
      debugPrint("🛑 Không có quyền hiển thị thông báo");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Vui lòng cấp quyền thông báo để nhận thông báo',
            style: GoogleFonts.lora(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    setState(() => _isDownloading = true);

    try {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        throw Exception("Không có quyền lưu ảnh");
      }

      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final Uint8List bytes = Uint8List.fromList(response.data);

      final tempDir = await getTemporaryDirectory();
      final fileName = "image_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final tempFile = File("${tempDir.path}/$fileName");
      await tempFile.writeAsBytes(bytes);

      await MediaStore.ensureInitialized();
      MediaStore.appFolder = 'SpaApp';

      final mediaStore = MediaStore();
      final result = await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.photo,
        dirName: DirName.pictures,
      );

      if (result != null) {
        await _showNotification();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Tải ảnh thành công vào thư viện',
              style: GoogleFonts.lora(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFD4A373),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception("Không thể lưu ảnh");
      }
    } catch (e) {
      debugPrint("🛑 Lỗi lưu ảnh: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Lỗi khi lưu ảnh: ${e.toString()}',
            style: GoogleFonts.lora(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final imageUrl = widget.formatImageUrl(widget.images[index]['url']);
              return InteractiveViewer(
                maxScale: 4.0,
                minScale: 1.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFFD4A373),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
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
              backgroundColor: const Color(0xFFD4A373),
              onPressed: _isDownloading
                  ? null
                  : () => _downloadImage(widget.formatImageUrl(widget.images[_currentIndex]['url'])),
              child: _isDownloading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(
                Icons.download,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.images.length}',
                  style: GoogleFonts.lora(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}