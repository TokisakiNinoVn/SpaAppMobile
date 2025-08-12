// file lib/services/realtime_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/app_config.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class RealtimeService {
  late WebSocketChannel _channel;
  final BuildContext context;
  final void Function(Map<String, dynamic>)? onUserStatusUpdate;

  RealtimeService(this.context, {this.onUserStatusUpdate});
  // Future<void> connect() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   final uri = Uri(
  //     scheme: 'ws',
  //     host: AppConfig.ip, //
  //     port: 5001,
  //     path: '/api/private/ws/account-status',
  //   );
  //
  //   try {
  //     final socket = await WebSocket.connect(
  //       uri.toString(),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //       },
  //     );
  //
  //     _channel = IOWebSocketChannel(socket);
  //
  //
  //     print('[RealtimeService] ✅ WebSocket đã sẵn sàng');
  //
  //     _channel.stream.listen(
  //       _handleEvent,
  //       onError: (error) {
  //         debugPrint('[RealtimeService] ❌ Lỗi WebSocket: $error');
  //       },
  //       onDone: () {
  //         debugPrint('[RealtimeService] 🔴 WebSocket đã đóng');
  //       },
  //     );
  //   } catch (e) {
  //     debugPrint('[RealtimeService] ❌ Không thể kết nối WebSocket: $e');
  //   }
  // }
  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final uri = Uri.parse(AppConfig.apiWebsocket);
    print("URL websocket: $uri");
    print("Token: $token");

    try {
      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("infor socket: ${socket.toString()}");

      _channel = IOWebSocketChannel(socket);

      print('[RealtimeService] ✅ WebSocket đã sẵn sàng');

      _channel.stream.listen(
        _handleEvent,
        onError: (error) {
          debugPrint('[RealtimeService] ❌ Lỗi WebSocket: $error');
        },
        onDone: () {
          debugPrint('[RealtimeService] 🔴 WebSocket đã đóng');
        },
      );
    } catch (e) {
      debugPrint('[RealtimeService] ❌ Không thể kết nối WebSocket: $e');
    }
  }


  Future<void> _handleEvent(dynamic event) async {
    try {
      final data = jsonDecode(event);
      // print("Data websocket: $data");
      if (data is Map<String, dynamic> && data['type'] == 'user_status_updated') {
        final userId = data['userId'];
        final technicianName = data['technicianName'];
        final status = data['status'] == true;
        final prefs = await SharedPreferences.getInstance();
        final String role = prefs.getString('role')?.replaceAll('"', '') ?? 'admin';

        // print('Phân Quyền: $role - Type: ${role.runtimeType}'); // Phân Quyền: admin - Type: String
        // print('[DEBUG] status raw: $status');

        if (status && role == 'admin') {
          _showNotification(
            title: 'Đã có nhân viên viên mới hoạt động',
            body: 'Nhân viên $technicianName đang hoạt động.',
          );
        }
        // else {
        //   debugPrint('[RealtimeService] 👤 Nhân viên $technicianName không hoạt động. Không gửi thông báo.');
        // }
        onUserStatusUpdate?.call(data);
      }
    } catch (e) {
      debugPrint('[RealtimeService] ❌ Lỗi khi decode dữ liệu: $e');
    }
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    bool hasPermission = true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Kiểm tra quyền
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          // Yêu cầu quyền nếu chưa có
          final result = await Permission.notification.request();
          hasPermission = result.isGranted;
        } else {
          hasPermission = true;
        }
      }
    }

    if (hasPermission) {
      const androidDetails = AndroidNotificationDetails(
        'account_status_channel',
        'Trạng thái tài khoản',
        channelDescription: 'Thông báo khi trạng thái người dùng thay đổi',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: 'ic_stat_check_circle',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        notificationDetails,
      );
    } else {
      debugPrint("🛑 Không có quyền hiển thị thông báo");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
        if (scaffoldMessenger != null) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                '❌ Vui lòng cấp quyền thông báo để nhận thông báo',
                style: GoogleFonts.lora(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          debugPrint("⚠️ ScaffoldMessenger chưa sẵn sàng.");
        }
      });
    }
  }

  void disconnect() {
    _channel.sink.close(status.goingAway);
    print('[RealtimeService] 🔌 Ngắt kết nối WebSocket');
  }
}
