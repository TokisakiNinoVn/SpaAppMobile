import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/screens/widgets/exit_confirm_dialog.dart';

import '../admin/widgets/account_widget.dart';
import '../admin/widgets/approve_widget.dart';
import '../admin/widgets/home_widget.dart';
import '../admin/widgets/account_admin_widget.dart';
// import '../admin/widgets/list_technician_widget.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  String? role;
  bool isLoading = true;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const AccountTab(),
    const ApproveTab(),
    const AccountAdminTab(),
    // const ListTechnicianTab(),
  ];

  // final List<String> _titles = [
  //   'Quản lý tài khoản',
  //   'Phê duyệt hồ sơ',
  //   'Kĩ thuật viên',
  //   'Chính sách & quyền',
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

  // Future<void> _logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  // }

  // void _showLogoutDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text("Đăng xuất"),
  //       content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
  //       actions: [
  //         TextButton(
  //           child: const Text("Hủy"),
  //           onPressed: () => Navigator.of(context).pop(),
  //         ),
  //         ElevatedButton(
  //           child: const Text("Đăng xuất"),
  //           onPressed: () async {
  //             await _logout();
  //             if (mounted) {
  //               Navigator.of(context).pop();
  //               context.go('/login');
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(content: Text("Đăng xuất thành công")),
  //               );
  //             }
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ExitAppWrapper (
      child: Scaffold(
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
            selectedItemColor: ColorConfig.primary,
            unselectedItemColor: ColorConfig.unselectedItemColor,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Tài khoản',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_turned_in),
                label: 'Phê duyệt',
              ),
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.person_outline),
              //   label: 'Hồ sơ',
              // ),
              BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: 'Đăng xuất',
              ),
            ],
          ),
        )
    );
  }
}
