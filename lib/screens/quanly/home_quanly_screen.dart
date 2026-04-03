import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/screens/quanly/widgets/list_city.dart';

// import '../admin/widgets/management_account_technician.dart';
// import '../admin/widgets/approve_widget.dart';
// import '../admin/widgets/account_admin_widget.dart';
// import 'package:spa_app/screens/quanly/widgets/list_technician_quanly_widget.dart';
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
    const ListCity(),
    const AccountQuanLyTab(),
  ];


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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
            label: 'KTV',
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
