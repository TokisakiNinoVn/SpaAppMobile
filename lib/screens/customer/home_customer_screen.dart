import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/check_login_helper.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
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
  bool isLoading = true;
  bool isLoggedIn = false;
  int _selectedIndex = 0;

  final Map<int, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();

    if (!mounted) return;

    setState(() {
      isLoggedIn = loggedIn;
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    // Tab Hoạt động cần login
    if (index == 1 && !isLoggedIn) {
      context.go(GlobalRouterConfig.signup);
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    if (_pageCache.containsKey(index)) {
      return _pageCache[index]!;
    }

    switch (index) {
      case 0:
        return _pageCache[index] = const HomeCustomerTab();
      case 1:
        return _pageCache[index] = const ActivityCustomerTab();
      case 2:
        return _pageCache[index] = const AccountCustomerTab();
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ExitAppWrapper(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: ColorConfig.primaryBackground,
          body: SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(3, (index) => _getPage(index)),
            ),
          ),
          // bottomNavigationBar: Container(
          //   decoration: const BoxDecoration(
          //     border: Border(
          //       top: BorderSide(
          //         color: Color(0x2C000000),
          //         width: 0.3,
          //       ),
          //     ),
          //   ),
          //   child: BottomNavigationBar(
          //     currentIndex: _selectedIndex,
          //     onTap: _onItemTapped,
          //     selectedItemColor: ColorConfig.primary,
          //     unselectedItemColor: ColorConfig.unselectedItemColor,
          //     type: BottomNavigationBarType.fixed,
          //     items: const [
          //       BottomNavigationBarItem(
          //         icon: Icon(Icons.home),
          //         label: 'Khám phá',
          //       ),
          //       BottomNavigationBarItem(
          //         icon: Icon(Icons.calendar_today),
          //         label: 'Hoạt động',
          //       ),
          //       BottomNavigationBarItem(
          //         icon: Icon(Icons.account_circle),
          //         label: 'Tài khoản',
          //       ),
          //     ],
          //   ),
          // ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0x2C000000),
                  width: 0.3,
                ),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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

        ),
      ),
    );
  }
}
