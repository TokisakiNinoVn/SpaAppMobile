import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:spa_app/routes/app_router.dart';

class NotificationHandler {
  static void handleTap(String? payload) {
    if (payload != null && payload.startsWith('order_')) {
      final orderId = payload.substring(6);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        appRouter.go('/home-technician/orders/$orderId');
      });
    }
  }

  static void handleForegroundMessage(RemoteMessage message) {
    final orderId = message.data['orderId'];

    // if (orderId != null) {
    //   _showDialog(orderId);
    // }
    appRouter.go('/home-technician/orders/$orderId');
  }

  static void _showDialog(String orderId) {
    final context = appRouter.routerDelegate.navigatorKey.currentContext;

    if (context == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đơn mới'),
        content: const Text('Bạn có muốn xem không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              appRouter.go('/home-technician/orders/$orderId');
            },
            child: const Text('Xem'),
          ),
        ],
      ),
    );
  }
}
