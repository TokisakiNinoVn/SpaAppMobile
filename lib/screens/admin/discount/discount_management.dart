import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/user_service.dart';
import '../../../../helper/snackbar_helper.dart';

class BannerManagement extends StatefulWidget {
  const BannerManagement({super.key});
  @override
  _AccountTabState createState() => _AccountTabState();
}

class _AccountTabState extends State<BannerManagement> {
  final UserService userService = UserService();

  List<Map<String, dynamic>> banner = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý banner"),
      ),
      body: Column(
        children: [],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
