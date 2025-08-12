import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AccountQuanLyTab extends StatefulWidget {
  const AccountQuanLyTab({super.key});

  @override
  State<AccountQuanLyTab> createState() => _AccountQuanLyTabState();
}

class _AccountQuanLyTabState extends State<AccountQuanLyTab> {
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Đăng xuất"),
            onPressed: () async {
              await _logout();
              if (!mounted) return;
              Navigator.of(context).pop();
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đăng xuất thành công")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('Màn hình tài khoản', style: TextStyle(fontSize: 20)),
          ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
