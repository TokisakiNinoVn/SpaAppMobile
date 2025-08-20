import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';

class AccountAdminTab extends StatefulWidget {
  const AccountAdminTab({super.key});

  @override
  State<AccountAdminTab> createState() => _AccountAdminTabState();
}

class _AccountAdminTabState extends State<AccountAdminTab> {
  Map<String, dynamic>? userInfo;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Logo
          Image.asset(
            'lib/assets/images/spa_logo.png',
            height: 100,
          ),
          const SizedBox(height: 20),

          Text(
            "Serene Spa",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Text(
            "Tài khoản quản trị",
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          Text(
            "Chào mừng bạn đến với trang quản trị hệ thống. Tại đây, bạn có thể kiểm soát, cấu hình và quản lý toàn bộ hoạt động của ứng dụng.",
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Thông tin người dùng
          if (userInfo != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(userInfo!['phone'] ?? '', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.blueGrey),
                      const SizedBox(width: 8),
                      Text(userInfo!['password'] ?? '', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Nút đăng xuất
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout),
              label: const Text("Đăng xuất"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: ColorConfig.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
