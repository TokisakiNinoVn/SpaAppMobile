import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/widgets/account_widget.dart';
import 'admin/widgets/home_widget.dart';
import 'admin/widgets/policy_widget.dart';
import 'admin/widgets/profile_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? role;
  bool isLoading = true;
  int _selectedIndex = 0;

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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Xác nhận đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Đăng xuất"),
            onPressed: () async {
              await _logout();
              if (mounted) {
                Navigator.of(context).pop();
                context.go("/login");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đăng xuất thành công!")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('inforUserLogin');
    await prefs.remove('role');
    await prefs.setBool('isLogin', false);
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return HomeTab(role: role ?? 'Không rõ');
      case 1:
        return const AccountTab();
      case 2:
        return const ProfileTab();
      case 3:
        return const PolicyTab();
      default:
        return const Center(child: Text("Không tìm thấy tab."));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 24.0,
        selectedFontSize: 12.0,
        unselectedFontSize: 10.0,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_rounded), label: 'Tài khoản'),
          BottomNavigationBarItem(icon: Icon(Icons.document_scanner_rounded), label: 'Kĩ thuật viên'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Chính sách'),
        ],
      ),
    );
  }
}