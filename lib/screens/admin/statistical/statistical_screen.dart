import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/user_service.dart';
import '../../../../helper/snackbar_helper.dart';

class StatisticalScreen extends StatefulWidget {
  const StatisticalScreen({super.key});
  @override
  _StatisticalScreenState createState() => _StatisticalScreenState();
}

class _StatisticalScreenState extends State<StatisticalScreen> {
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
        title: Text("Thống kê"),
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
