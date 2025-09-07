import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/notification_service.dart';

class AccountAdminTab extends StatefulWidget {
  const AccountAdminTab({super.key});

  @override
  State<AccountAdminTab> createState() => _AccountAdminTabState();
}

class _AccountAdminTabState extends State<AccountAdminTab> {
  Map<String, dynamic>? userInfo;
  final NotificationService _notificationService = NotificationService();

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userInfoJson = prefs.getString('loginData');
    if (userInfoJson != null) {
      final decoded = json.decode(userInfoJson);
      setState(() {
        userInfo = decoded;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Đăng xuất",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await _logout();
              if (!mounted) return;
              Navigator.of(context).pop();
              context.go('/login');
              SnackbarHelper.showSuccess(context, "Đăng xuất thành công");
            },
            icon: const Icon(Icons.logout),
            label: const Text("Đăng xuất"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với avatar và thông tin
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorConfig.primary.withOpacity(0.1),
                        border: Border.all(
                          color: ColorConfig.primary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: ColorConfig.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Serene Spa",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tài khoản quản trị",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card thông tin tài khoản
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
                        "Thông tin tài khoản",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (userInfo != null) ...[
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: "Số điện thoại",
                          value: userInfo!['phone'] ?? '',
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(
                          icon: Icons.lock,
                          label: "Mật khẩu",
                          value: userInfo!['password'] ?? '',
                          obscureValue: true,
                        ),
                      ] else
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Card chức năng
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                      // const SizedBox(height: 12),
                      // _buildFunctionButton(
                      //   context,
                      //   icon: Icons.settings,
                      //   title: "Cài đặt hệ thống",
                      //   subtitle: "Cấu hình ứng dụng",
                      //   onTap: () {},
                      //   color: Colors.blue,
                      // ),
                      // const SizedBox(height: 12),
                      // _buildFunctionButton(
                      //   context,
                      //   icon: Icons.analytics,
                      //   title: "Thống kê",
                      //   subtitle: "Xem báo cáo hoạt động",
                      //   onTap: () {},
                      //   color: Colors.green,
                      // ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nút đăng xuất
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Đăng xuất"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Footer
              Center(
                child: Text(
                  "Phiên bản 1.0.0",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool obscureValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueGrey, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                obscureValue ? "••••••••" : value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
}