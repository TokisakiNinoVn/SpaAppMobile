import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/screens/customer/tabs/account_customer_tab.dart';
import 'package:spa_app/screens/customer/tabs/activity_customer_tab.dart';
import 'package:spa_app/screens/customer/tabs/home_customer_tab.dart';
import 'package:spa_app/screens/widgets/exit_confirm_dialog.dart';

class HomeCustomerScreen extends StatefulWidget {
  const HomeCustomerScreen({super.key});

  @override
  State<HomeCustomerScreen> createState() => _HomeCustomerScreenState();
}

class _HomeCustomerScreenState extends State<HomeCustomerScreen> {
  String? role;
  bool isLoading = true;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeCustomerTab(),
    const ActivityCustomerTab(),
    const AccountCustomerTab(),
  ];

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        isLoading = false;
      });
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

    return ExitAppWrapper(
      child: Scaffold(
        body: SafeArea(child: _pages[_selectedIndex]),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Color(0x2C000000),
                width: 0.3,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: ColorConfig.primary,
            unselectedItemColor: ColorConfig.unselectedItemColor,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Khám phá',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Hoạt động',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
