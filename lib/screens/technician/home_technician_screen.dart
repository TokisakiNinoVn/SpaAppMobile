import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/providers/selected_tab_provider.dart';
import 'package:spa_app/screens/technician/tabs/account_widget.dart';
import 'package:spa_app/screens/technician/tabs/home_widget.dart';
import 'package:spa_app/screens/technician/tabs/get_job_tab_widget.dart';
import 'package:spa_app/screens/technician/tabs/management_technician_widget_tab.dart';
import 'package:spa_app/screens/technician/tabs/order_tab_widget.dart';
import 'package:spa_app/screens/technician/tabs/policy_tab_widget.dart';
import 'package:spa_app/screens/technician/tabs/support_tab_widget.dart';

class HomeTechnicianScreen extends StatefulWidget {

  final int initialIndex;
  const HomeTechnicianScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeTechnicianScreen> createState() => _HomeTechnicianScreenState();
}

class _HomeTechnicianScreenState extends State<HomeTechnicianScreen> {
  String? role;
  bool isLoading = true;
  bool isTechnicianActive = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SelectedTabProvider>()
          .setIndex(widget.initialIndex);
    });

    _loadRoleType();
  }

  Future<void> _loadRoleType() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      role = prefs.getString('role') ?? 'Không rõ';
      isLoading = false;
      isTechnicianActive =
          prefs.getBool('isTechnicianActive') == true;
    });
  }

  void _onItemTapped(int index) {
    context.read<SelectedTabProvider>().setIndex(index);
  }

  Widget _buildBody(int selectedIndex) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (isTechnicianActive) {
      switch (selectedIndex) {
        case 0:
          return const HomeTechnicianTab();
        case 1:
          return const OrderTab();
        case 2:
          return const JobApplicationTab();
        case 3:
          return const AccountTab();
        default:
          return const Center(
            child: Text("Không tìm thấy tab."),
          );
      }
    } else {
      switch (selectedIndex) {
        case 0:
          return const HomeTechnicianTab();
        case 1:
          return const PolicyTabWidget();
        case 2:
          return const SupportTabWidget();
        case 3:
          return const AccountTab();
        default:
          return const Center(
            child: Text("Không tìm thấy tab."),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        context.watch<SelectedTabProvider>().selectedIndex;

    return Scaffold(
      body: SafeArea(
        child: _buildBody(selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        iconSize: 24.0,
        selectedFontSize: 12.0,
        unselectedFontSize: 10.0,
        selectedItemColor: ColorConfig.primary,
        unselectedItemColor:
        ColorConfig.unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: isTechnicianActive
            ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Đơn việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_added),
            label: 'Nhận việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ]
            : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Chính sách',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone),
            label: 'Hỗ trợ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
