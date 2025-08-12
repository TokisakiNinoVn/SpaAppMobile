import 'package:flutter/material.dart';
import 'dart:io';

/// Hàm hiện dialog xác nhận thoát
Future<bool> showExitConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Không cho tắt dialog khi bấm ra ngoài
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          "Xác nhận thoát",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Bạn có chắc muốn thoát ứng dụng không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Thoát"),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

/// Widget bọc màn hình chính để chặn nút back
class ExitAppWrapper extends StatelessWidget {
  final Widget child;
  const ExitAppWrapper({super.key, required this.child});

  Future<bool> _onWillPop(BuildContext context) async {
    bool shouldExit = await showExitConfirmDialog(context);
    if (shouldExit) {
      exit(0); // Thoát ứng dụng
    }
    return false; // Không thoát mặc định
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: child,
    );
  }
}
