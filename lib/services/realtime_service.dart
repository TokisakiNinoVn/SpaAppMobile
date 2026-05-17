// file lib/services/realtime_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/app_config.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class RealtimeService {
  late WebSocketChannel _channel;
  final BuildContext? context;
  final void Function(Map<String, dynamic>)? onUserStatusUpdate;
  final void Function(Map<String, dynamic>)? onNewOrder;
  final void Function(String orderId)? onOrderExpired;
  final void Function(String orderId)? onOrderRemoved;
  bool _isDisposed = false;

  // RealtimeService(this.context, {this.onUserStatusUpdate});
  // RealtimeService({this.context, this.onUserStatusUpdate}) {
  //   // ⚡ Đây là vị trí đúng cho đoạn kiểm tra môi trường
  //   if (AppConfig.isProduction) {
  //     // Cậu có thể thêm logic đặc biệt cho production ở đây
  //   }
  // }

  RealtimeService({
    this.context,
    this.onUserStatusUpdate,
    this.onNewOrder,
    this.onOrderExpired,
    this.onOrderRemoved,
  });

  void dispose() {
    _isDisposed = true;
    // Hủy subscription...
  }

  int _reconnectDelay = 2000; // bắt đầu 2s
  final int _maxReconnectDelay = 30000;

  // Dùng cái này khi AppConfig.isProduction == true
  // Future<void> connect() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //
  //   // 🚧 Tránh kết nối khi chưa có token — tránh crash WebSocket
  //   if (token == null || token.isEmpty) {
  //     appLog("[RealtimeService] ❌ Không tìm thấy token để kết nối WebSocket");
  //     return;
  //   }
  //
  //   // ⚙️ Tự động chọn link websocket dựa vào environment
  //   final uri = AppConfig.isProduction
  //       ? Uri.parse(AppConfig.apiWebsocket)
  //       : Uri(
  //     scheme: 'ws',
  //     host: AppConfig.ip,
  //     port: 5001,
  //     path: '/api/private/ws/realtime',
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
  //     _channel.stream.listen(
  //       _handleEvent,
  //       onError: (error) {
  //         appLog('[RealtimeService] ❌ Lỗi WebSocket: $error');
  //       },
  //       onDone: () {
  //         appLog('[RealtimeService] 🔴 WebSocket đã đóng');
  //       },
  //     );
  //   } catch (e) {
  //     appLog('[RealtimeService] ❌ Không thể kết nối WebSocket: $e');
  //   }
  // }

  Future<void> connect() async {
    if (_isDisposed) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      appLog("[RealtimeService] ❌ Không có token");
      return;
    }

    final uri = AppConfig.isProduction
        ? Uri.parse(AppConfig.apiWebsocket)
        : Uri(
      scheme: 'ws',
      host: AppConfig.ip,
      port: 5001,
      path: '/api/private/ws/realtime',
    );

    try {
      appLog('[RealtimeService] 🔌 Connecting...');

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: {'Authorization': 'Bearer $token'},
      );

      _channel = IOWebSocketChannel(socket);

      // reset delay khi connect thành công
      _reconnectDelay = 5000;

      _channel.stream.listen(
        _handleEvent,
        onError: (error) {
          appLog('[RealtimeService] ❌ Error: $error');
          _reconnect();
        },
        onDone: () {
          appLog('[RealtimeService] 🔴 Closed');
          _reconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      appLog('[RealtimeService] ❌ Connect fail: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed) return;

    appLog('[RealtimeService] 🔄 Reconnecting in ${_reconnectDelay / 1000}s');

    Future.delayed(Duration(milliseconds: _reconnectDelay), () {
      if (_isDisposed) return;

      connect();

      // exponential backoff
      _reconnectDelay = (_reconnectDelay * 2).clamp(2000, _maxReconnectDelay);
    });
  }


  Future<void> _handleEvent(dynamic event) async {
    try {
      final data = jsonDecode(event);

      if (data is Map<String, dynamic> && data['type'] == 'user_status_updated') {
        // final userId = data['userId'];
        final technicianName = data['technicianName'];
        final status = data['status'] == true;
        final prefs = await SharedPreferences.getInstance();
        final String role =
            prefs.getString('role')?.replaceAll('"', '') ?? 'admin';

        if (status && role == 'admin') {
          _showNotification(
            title: 'Đã có nhân viên viên mới hoạt động',
            body: 'Nhân viên $technicianName đang hoạt động.',
          );
        }
        onUserStatusUpdate?.call(data);
      }
      else if (data is Map<String, dynamic> &&
          data['type'] == 'notification_from_admin') {
        final prefs = await SharedPreferences.getInstance();
        final String role =
            prefs.getString('role')?.replaceAll('"', '') ?? 'admin';

        // Nếu role là kỹ thuật viên thì nhận thông báo từ admin
        if (role == 'ktv') {
          _showNotification(
            title: data['title'] ?? 'Thông báo từ admin',
            body: data['content'] ?? '',
          );
        }
      }
      else if (data['type'] == 'NEW_ORDER') {
        final order = data['data'];

        onNewOrder?.call(order);

        // 🔔 optional: show local notification nếu muốn
        // _showNotification(
        //   title: 'Đơn mới',
        //   body: 'Bạn có một đơn việc mới',
        // );
      }
      else if (data['type'] == 'ORDER_EXPIRED') {
        final orderId = data['orderId'];

        onOrderExpired?.call(orderId);
      }
      else if (data['type'] == 'remove-order') {
        final orderId = data['data']?['orderId'];

        if (orderId != null) {
          onOrderRemoved?.call(orderId);

          _showNotification(
            title: 'Đơn việc đã bị xoá',
            body: data['data']?['message'] ?? '',
          );
        }
      }

    } catch (e) {
      appLog('[RealtimeService] ❌ Lỗi khi decode dữ liệu: $e');
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
      appLog("🛑 Không có quyền hiển thị thông báo");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffoldMessenger = ScaffoldMessenger.maybeOf(context!);
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
          appLog("⚠️ ScaffoldMessenger chưa sẵn sàng.");
        }
      });
    }
  }

  void disconnect() {
    _channel.sink.close(status.goingAway);
    appLog('[RealtimeService] 🔌 Ngắt kết nối WebSocket');
  }
}
