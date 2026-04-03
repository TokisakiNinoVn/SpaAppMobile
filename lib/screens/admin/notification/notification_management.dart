import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/user_service.dart';
import '../../../../helper/snackbar_helper.dart';
import '../../../services/notification_service.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});
  @override
  _NotificationManagementScreenState createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final UserService userService = UserService();
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> banner = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý thông báo"),
      ),
      body: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chức năng quản trị",
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                  const SizedBox(height: 16),
                  _buildFunctionButton(
                    context,
                    icon: Icons.notifications_active,
                    title: "Gửi thông báo",
                    subtitle: "Gửi thông báo đến kỹ thuật viên",
                    onTap: () => _showCreateNotificationDialog(context),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required Color color,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showCreateNotificationDialog(BuildContext context) {
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Tạo thông báo",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contentController,
              maxLength: 100,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Nội dung thông báo",
                hintText: "Nhập nội dung (<100 ký tự)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Thông báo này sẽ được gửi đến tất cả kỹ thuật viên",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              final content = contentController.text.trim();

              if (content.isEmpty) {
                SnackbarHelper.showError(context, "Nội dung không được để trống");
                return;
              }
              if (content.length > 100) {
                SnackbarHelper.showError(context, "Nội dung không quá 100 ký tự");
                return;
              }

              try {
                await _notificationService.createNotificationService({"content": content});
                if (!mounted) return;
                Navigator.of(context).pop();
                SnackbarHelper.showSuccess(context, "Tạo thông báo thành công");
              } catch (e) {
                if (!mounted) return;
                SnackbarHelper.showError(context, "Tạo thông báo thất bại");
              }
            },
            child: const Text("Gửi thông báo"),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
  }
}
