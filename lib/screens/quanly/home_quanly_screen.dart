import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../admin/widgets/account_widget.dart';
import '../admin/widgets/approve_widget.dart';
// import '../admin/widgets/account_admin_widget.dart';
import 'package:spa_app/screens/quanly/widgets/list_technician_quanly_widget.dart';
import 'package:spa_app/screens/quanly/widgets/account_widget.dart';

class HomeQuanLyScreen extends StatefulWidget {
  const HomeQuanLyScreen({super.key});

  @override
  State<HomeQuanLyScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeQuanLyScreen> {
  String? role;
  bool isLoading = true;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    // const AccountTab(),
    const QuanLyListTechnicianTab(),
    const AccountQuanLyTab(),
    // const PolicyTab(),
  ];

  // final List<String> _titles = [
  //   // 'Quản lý tài khoản',
  //   'Phê duyệt hồ sơ',
  //   'Kĩ thuật viên',
  //   // 'Chính sách & quyền',
  // ];

  @override
  void initState() {
    super.initState();
    _loadRoleType();
  }

  Future<void> _loadRoleType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'Không rõ';
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
              if (mounted) {
                Navigator.of(context).pop();
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đăng xuất thành công")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(_titles[_selectedIndex]),
      //   centerTitle: true,
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.settings),
      //       tooltip: 'Cài đặt',
      //       onPressed: () => context.go('/settings'),
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       tooltip: 'Đăng xuất',
      //       onPressed: () => _showLogoutDialog(context),
      //     ),
      //   ],
      // ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.account_circle),
          //   label: 'Tài khoản',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Kĩ thuật viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Tài khoản',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.account_circle_rounded),
          //   label: 'Tài khoản',
          // ),
        ],
      ),
    );
  }
}
