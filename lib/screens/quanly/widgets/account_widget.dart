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
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('lib/assets/images/img_1.png'),
                // Nếu có link thì thay NetworkImage(...)
              ),
              const SizedBox(height: 12),

              // Tên user
              const Text(
                'Serene Spa',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Tận tâm với khách hàng',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // const Divider(),

              // Các tuỳ chọn khác
              // ListTile(
              //   leading: const Icon(Icons.lock_outline),
              //   title: const Text("Đổi mật khẩu"),
              //   onTap: () {},
              // ),
              // ListTile(
              //   leading: const Icon(Icons.support_agent),
              //   title: const Text("Hỗ trợ khách hàng"),
              //   onTap: () {},
              // ),
              // ListTile(
              //   leading: const Icon(Icons.info_outline),
              //   title: const Text("Giới thiệu Serene Spa"),
              //   onTap: () {},
              // ),

              const Divider(),

              // Nút đăng xuất
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.white,),
                label: const Text('Đăng xuất', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
