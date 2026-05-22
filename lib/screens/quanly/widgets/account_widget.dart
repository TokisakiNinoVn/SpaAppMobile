import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/screens/widgets/role_switcher_card.dart';
import 'package:spa_app/services/auth_service.dart';

import '../../../helper/shared_preferences_helper.dart';
import '../../../storage/index.dart';
import '../../customer/tabs/widgets/switch_role_widget.dart';

class AccountQuanLyTab extends StatefulWidget {
  const AccountQuanLyTab({super.key});

  @override
  State<AccountQuanLyTab> createState() => _AccountQuanLyTabState();
}

class _AccountQuanLyTabState extends State<AccountQuanLyTab> {
  final AuthService authService = AuthService();

  bool isLoading = false;

  String rolesActive = '';
  List<String> roles = [];
  bool get isAdmin => AppConfig.adminPhone.contains(userInfo?['phone']);
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  void loadUserInfo() async {
    final userInfoJson = await SharedPrefs.getValue(PrefType.string, "inforUserLogin") ?? '';
    final rolesActiveStr = await SharedPrefs.getValue(PrefType.string, "rolesActive") ?? '';
    final rolesJsonStr = await SharedPrefs.getValue(PrefType.string, "roles") ?? '[]';

    List<String> rolesList = [];
    if (rolesJsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = json.decode(rolesJsonStr);
        rolesList = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        rolesList = [];
      }
    }


    Map<String, dynamic>? user;
    if (userInfoJson.isNotEmpty) {
      user = json.decode(userInfoJson);
    }

    if (mounted) {
      setState(() {
        rolesActive = rolesActiveStr;
        roles = rolesList;
        userInfo = user;
      });
    }
  }

  // Xử lý chuyển đổi vai trò (đã tách logic khỏi UI)
  Future<void> _handleSwitchRole(String newRole) async {
    if (newRole == rolesActive) {
      SnackBarHelper.showWarning(context, "Bạn đang ở vai trò ${_getRoleDisplayName(newRole)}");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.switchRoleAccount({
        "roleChangeTo": newRole,
      });
      await SharedPreferencesHelper.logOut();

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );
    } catch (e) {
      appLog('Lỗi chuyển vai trò: $e');
      SnackBarHelper.showError(
        context,
        "Lỗi kết nối hoặc hệ thống. Vui lòng thử lại!",
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getRoleDisplayName(String roleKey) {
    switch (roleKey) {
      case 'admin':
        return 'Quản trị viên';
      case 'ktv':
        return 'KTV';
      case 'customer':
        return 'Khách hàng';
      case 'quanly':
        return 'Quản lý';
      default:
        return roleKey;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất không?"),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Đăng xuất"),
            onPressed: () async {
              await SharedPreferencesHelper.logOut();
              if (!mounted) return;
              Navigator.of(context).pop();
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đăng xuất thành công")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('lib/assets/images/img_1.png'),
                // Nếu có link thì thay NetworkImage(...)
              ),
              const SizedBox(height: 12),
              if (isAdmin && roles.isNotEmpty)
                RoleSwitcherCard(
                  roles: roles,
                  activeRole: rolesActive,
                  onSwitchRole: _handleSwitchRole,
                  isSwitching: isLoading,
                ),

              const SizedBox(height: 12),

              // Tên user
              const Text(
                'Serene Spa',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Tận tâm với khách hàng',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // const Divider(),

              // Các tuỳ chọn khác
              // ListTile(
              //   leading: const Icon(Icons.lock_outline),
              //   title: const Text("Đổi mật khẩu"),
              //   onTap: () {},
              // ),
              // ListTile(
              //   leading: const Icon(Icons.support_agent),
              //   title: const Text("Hỗ trợ khách hàng"),
              //   onTap: () {},
              // ),
              // ListTile(
              //   leading: const Icon(Icons.info_outline),
              //   title: const Text("Giới thiệu Serene Spa"),
              //   onTap: () {},
              // ),

              const Divider(),

              // Nút đăng xuất
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, color: Colors.white,),
                label: const Text('Đăng xuất', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
