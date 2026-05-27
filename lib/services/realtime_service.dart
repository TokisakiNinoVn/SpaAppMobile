// file lib/services/realtime_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class RealtimeService {
  // =========================================================
  // SINGLETON THẬT
  // =========================================================

  RealtimeService._internal();

  static final RealtimeService _instance = RealtimeService._internal();

  static RealtimeService get instance => _instance;

  // =========================================================
  // VARIABLES
  // =========================================================

  WebSocketChannel? _channel;

  bool _isDisposed = false;
  bool _isConnecting = false;
  bool _isConnected = false;

  BuildContext? context;

  int _reconnectDelay = 2000;
  final int _maxReconnectDelay = 30000;

  StreamSubscription? _socketSubscription;

  // =========================================================
  // CALLBACKS
  // =========================================================

  void Function(Map<String, dynamic>)? onUserStatusUpdate;
  void Function(Map<String, dynamic>)? onNewOrder;
  void Function(String orderId)? onOrderExpired;
  void Function(String orderId)? onOrderRemoved;
  void Function(Map<String, dynamic>)? onNewOrderAutoMatching;
  void Function(String orderId)? onOrderAutoMatchingRemove;

  // =========================================================
  // LISTENERS
  // =========================================================

  final List<Function(dynamic data)> onNewTechnicianApplyOrderListeners = [];
  List<Function(Map<String, dynamic>)> onUserStatusUpdateListeners = [];

  // =========================================================
  // INIT
  // =========================================================

  Future<void> init({
    BuildContext? context,
  }) async {
    this.context = context;

    appLog('[RealtimeService] INSTANCE => ' '${identityHashCode(this)}');

    await connect();
  }

  // =========================================================
  // CONNECT
  // =========================================================

  Future<void> connect() async {
    if (_isDisposed) return;

    if (_isConnecting) {
      appLog('[RealtimeService] ⚠️ Đang connect rồi');
      return;
    }

    if (_isConnected) {
      appLog('[RealtimeService] ⚠️ Đã connected');
      return;
    }

    _isConnecting = true;

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      appLog("[RealtimeService] ❌ Không có token");

      _isConnecting = false;
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
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _channel = IOWebSocketChannel(socket);

      _isConnected = true;
      _isConnecting = false;

      _reconnectDelay = 5000;

      appLog('[RealtimeService] ✅ Connected');

      _socketSubscription = _channel!.stream.listen(
        _handleEvent,
        onError: (error) {
          appLog('[RealtimeService] ❌ Error: $error');

          _isConnected = false;
          _isConnecting = false;

          _reconnect();
        },
        onDone: () {
          appLog('[RealtimeService] 🔴 Closed');

          _isConnected = false;
          _isConnecting = false;

          _reconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      appLog('[RealtimeService] ❌ Connect fail: $e');

      _isConnected = false;
      _isConnecting = false;

      _reconnect();
    }
  }

  // =========================================================
  // RECONNECT
  // =========================================================

  void _reconnect() {
    if (_isDisposed) return;

    Future.delayed(
      Duration(milliseconds: _reconnectDelay),
          () async {
        if (_isDisposed) return;

        appLog('[RealtimeService] 🔄 Reconnecting...');

        await connect();

        _reconnectDelay = (_reconnectDelay * 2).clamp(2000, _maxReconnectDelay);
      },
    );
  }

  // =========================================================
  // HANDLE EVENT
  // =========================================================

  Future<void> _handleEvent(dynamic event) async {
    try {
      final data = jsonDecode(event);
      appLog("[RealtimeService] 📩 Data realtime: ${data}");

      if (data is! Map<String, dynamic>) {
        return;
      }

      final type = data['type'];

      // =====================================================
      // USER STATUS
      // =====================================================

      if (type == 'user_status_updated') {
        final technicianName = data['technicianName'];

        final status = data['status'] == true;

        final prefs = await SharedPreferences.getInstance();

        final String role = prefs.getString('role')?.replaceAll('"', '') ?? 'admin';

        if (status && role == 'admin') {
          _showNotification(
            title: 'Đã có nhân viên mới hoạt động',
            body: 'Nhân viên $technicianName đang hoạt động.',
          );
        }

        // onUserStatusUpdate?.call(data);
        for (final listener in onUserStatusUpdateListeners) {
          listener(data);
        }
      }

      // =====================================================
      // NOTIFICATION
      // =====================================================

      else if (type == 'notification_from_admin') {
        final prefs = await SharedPreferences.getInstance();

        final String role = prefs.getString('role')?.replaceAll('"', '') ?? 'admin';

        if (role == 'ktv') {
          _showNotification(
            title: data['title'] ?? 'Thông báo từ admin',
            body: data['content'] ?? '',
          );
        }
      }

      // =====================================================
      // NEW ORDER
      // =====================================================

      else if (type == 'NEW_ORDER') {
        final order = Map<String, dynamic>.from(data['data'] ?? {});

        onNewOrder?.call(order);
      }

      // =====================================================
      // AUTO MATCHING
      // =====================================================

      else if (type == 'new_automatching_order') {
        final order = Map<String, dynamic>.from(data['data'] ?? {});

        appLog("[RealtimeService] 📦 Auto matching: $order");

        onNewOrderAutoMatching?.call(order);
      }

      // =====================================================
      // ORDER EXPIRED
      // =====================================================

      else if (type == 'ORDER_EXPIRED') {
        final orderId = data['orderId']?.toString();

        if (orderId != null) {
          onOrderExpired?.call(orderId);
        }
      }

      // =====================================================
      // TECHNICIAN APPLY
      // =====================================================

      else if (type == 'technician_apply') {
        final dataApply = Map<String, dynamic>.from(data['data'] ?? {});

        // appLog("[RealtimeService] 👨‍🔧 Technician apply: $dataApply");
        //
        // appLog("[RealtimeService] 👂 Listener count: ${onNewTechnicianApplyOrderListeners.length}");

        for (final listener in onNewTechnicianApplyOrderListeners) {
          try {
            listener(dataApply);
          } catch (e) {
            appLog('[RealtimeService] ❌ Listener error: $e');
          }
        }
      }

      // =====================================================
      // REMOVE ORDER
      // =====================================================

      else if (type == 'remove-order') {
        final orderId = data['data']?['orderId']?.toString();

        if (orderId != null) {
          onOrderRemoved?.call(orderId);

          // _showNotification(
          //   title: 'Đơn việc đã bị xoá',
          //   body: data['data']?['message'] ?? '',
          // );
        }
      }
    } catch (e) {
      appLog('[RealtimeService] ❌ Lỗi handle event: $e');
    }
  }

  // =========================================================
  // ADD LISTENER
  // =========================================================

  void addTechnicianApplyListener(Function(dynamic data) listener) {
    final existed = onNewTechnicianApplyOrderListeners.contains(listener);

    if (existed) return;

    onNewTechnicianApplyOrderListeners.add(listener);

    appLog('[RealtimeService] ➕ Add listener | Total: ${onNewTechnicianApplyOrderListeners.length}');
  }

  void addUserStatusListener(Function(Map<String, dynamic>) listener) {
    final existed = onUserStatusUpdateListeners.contains(listener);

    if (existed) return;

    onUserStatusUpdateListeners.add(listener);

    appLog(
      '[RealtimeService] ➕ Add user status listener | Total: ${onUserStatusUpdateListeners.length}',
    );
  }

  // =========================================================
  // REMOVE LISTENER
  // =========================================================

  void removeTechnicianApplyListener(Function(dynamic data) listener) {
    onNewTechnicianApplyOrderListeners.remove(listener);

    appLog( '[RealtimeService] ➖ Remove listener | Total: ${onNewTechnicianApplyOrderListeners.length}');
  }
  void removeUserStatusListener(Function(Map<String, dynamic>) listener) {
    onUserStatusUpdateListeners.remove(listener);

    appLog(
      '[RealtimeService] ➖ Remove user status listener | Total: ${onUserStatusUpdateListeners.length}',
    );
  }


  // =========================================================
  // NOTIFICATION
  // =========================================================

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    bool hasPermission = true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        var status = await Permission.notification.status;

        if (!status.isGranted) {
          final result = await Permission.notification.request();

          hasPermission = result.isGranted;
        }
      }
    }

    if (!hasPermission) {
      appLog("🛑 Không có quyền hiển thị thông báo");

      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'account_status_channel',
      'Trạng thái tài khoản',
      channelDescription: 'Thông báo realtime',
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
  }

  // =========================================================
  // DISCONNECT
  // =========================================================

  void disconnect() {
    try {
      _socketSubscription?.cancel();

      _channel?.sink.close(status.normalClosure);

      _isConnected = false;

      appLog('[RealtimeService] 🔌 Disconnected');
    } catch (e) {
      appLog('[RealtimeService] ❌ Disconnect error: $e');
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  void dispose() {
    _isDisposed = true;

    disconnect();

    onNewTechnicianApplyOrderListeners.clear();
    onNewTechnicianApplyOrderListeners.clear();
    onUserStatusUpdateListeners.clear();

    appLog('[RealtimeService] 🗑 Dispose');
  }
}