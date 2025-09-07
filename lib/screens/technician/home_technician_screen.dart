import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';

import 'package:spa_app/screens/technician/widgets/account_widget.dart';
import 'package:spa_app/screens/technician/widgets/home_widget.dart';
import 'package:spa_app/screens/technician/widgets/management_technician_widget_tab.dart';
import 'package:spa_app/screens/technician/widgets/policy_tab_widget.dart';
import 'package:spa_app/screens/technician/widgets/support_tab_widget.dart';
import 'package:spa_app/services/realtime_service.dart';

class HomeTechnicianScreen extends StatefulWidget {
  const HomeTechnicianScreen({super.key});

  @override
  State<HomeTechnicianScreen> createState() => _HomeTechnicianScreenState();
}

class _HomeTechnicianScreenState extends State<HomeTechnicianScreen> {
  String? role;
  bool isLoading = true;
  int _selectedIndex = 0;
  bool isTechnicianActive = false;
  // late RealtimeService _realtimeService;


  @override
  void initState() {
    super.initState();
    _loadRoleType();

    // _realtimeService = RealtimeService(
    //   context,
    // );
    // _realtimeService.connect();
  }

  Future<void> _loadRoleType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      role = prefs.getString('role') ?? 'Không rõ';
      isLoading = false;
      isTechnicianActive = prefs.getString('isTechnicianActive') == 'true';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedIndex) {
      case 0:
        return const HomeTab();
      case 1:
        return const PolicyTabWidget();
      case 2:
        return const SupportTabWidget();
      case 3:
        return const AccountTab();
      case 4:
        if (!isTechnicianActive) {
          return const Center(child: Text("Hồ sơ chưa được duyệt"));
        }
        return const ManagementTechnicianTab();
      default:
        return const Center(child: Text("Không tìm thấy tab."));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        iconSize: 24.0,
        selectedFontSize: 12.0,
        unselectedFontSize: 10.0,
        selectedItemColor: ColorConfig.primary,
        unselectedItemColor: ColorConfig.unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: isTechnicianActive
            ? const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Chính sách'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Hỗ trợ'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Tài khoản'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Hồ sơ'),
        ]
            : const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Chính sách'),
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Hỗ trợ'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
