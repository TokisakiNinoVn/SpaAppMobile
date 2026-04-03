import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/screens/admin/service/service_management.dart';
import 'package:spa_app/screens/admin/widgets/general_management_widget.dart';
import 'package:spa_app/screens/widgets/exit_confirm_dialog.dart';

import 'account/technician/management_account_technician.dart';
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
    // const ServiceTab(),
    // const AccountTab(),
    const ApproveTab(),
    const GeneralManagementTab(),
    const AccountAdminTab(),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ExitAppWrapper (
      child: Scaffold(
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

              // BottomNavigationBarItem(
              //   icon: Icon(Icons.calendar_today),
              //   label: 'Dịch vụ',
              // ),
              //
              // BottomNavigationBarItem(
              //   icon: Icon(Icons.manage_accounts_sharp),
              //   label: 'Tài khoản',
              // ),

              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_turned_in),
                label: 'Phê duyệt',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'QL Chung',
              ),

              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_rounded),
                label: 'Admin',
              ),
            ],
          ),
        )
    );
  }
}
