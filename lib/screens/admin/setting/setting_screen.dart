import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/user_service.dart';
import '../../../../helper/snackbar_helper.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
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
        title: Text("Cài đặt chung"),
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
