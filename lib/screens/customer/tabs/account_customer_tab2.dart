import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spa_app/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/user_service.dart';

import '../../../helper/check_login_helper.dart';

class AccountCustomerTab extends StatefulWidget {
  const AccountCustomerTab({super.key});

  @override
  State<AccountCustomerTab> createState() => _AccountCustomerTabState();
}

class _AccountCustomerTabState extends State<AccountCustomerTab> {
  final UserService _userService = UserService();
  bool _isSwitchingRole = false;
  Map<String, dynamic>? inforUser;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final loggedIn = await CheckLoginHelper.isLoggedIn();
    if (loggedIn)
      _loadInforUser();
    else
      context.go(GlobalRouterConfig.loginOTP);
  }

  Future<void> _loadInforUser() async {
    final prefs = await SharedPreferences.getInstance();
    SharedPreferencesHelper.listAllKeyValue();

    final jsonString = prefs.getString('inforUserLogin');

    if (jsonString == null) {
      inforUser = null;
      debugPrint('❌ Không có dữ liệu');
      return;
    }

    try {
      inforUser = jsonDecode(jsonString) as Map<String, dynamic>;
      debugPrint('✅ Thông tin user: $inforUser');
    } catch (e) {
      debugPrint('❌ Lỗi parse customerProfile: $e');
      inforUser = null;
    }
  }

  Future<void> _changeRole() async {
    try {
      setState(() {
        _isSwitchingRole = true;
      });

      final response = await _userService.changeRoleService({});
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Đã chuyển đổi vai trò thành công. Vui lòng đăng nhập lại!",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        await _logout();
        context.go("/login");
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Có lỗi xảy ra khi chuyển đổi vai trò",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Lỗi: $e",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingRole = false;
        });
      }
    }
  }

  void _showRoleSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.switch_account, color: Color(0xFF8B7355)),
            SizedBox(width: 10),
            Text(
              "Chuyển đổi vai trò",
              style: TextStyle(
                color: Color(0xFF8B7355),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Bạn muốn chuyển sang vai trò kỹ thuật nhân viên?\nSau khi chuyển đổi, bạn cần đăng nhập lại bằng số điện thoại này.",
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Hủy",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _changeRole();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B7355),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Chuyển đổi",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text(
              "Đăng xuất",
              style: TextStyle(
                color: Color(0xFF8B7355),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?",
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Hủy",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _logout();
              if (!mounted) return;
              Navigator.of(context).pop();
              context.go(GlobalRouterConfig.loginOTP);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Đăng xuất thành công"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9F5F0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ===== HEADER USER =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar với khung viền trang trí
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4B996), Color(0xFF8B7355)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage:
                        const AssetImage('lib/assets/images/img_3.png'),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Info User
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inforUser?['phone'] ?? '...',
                            style: TextStyle(
                              color: ColorConfig.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
                      ),
                    ),

                    // Nút chuyển đổi role
                    _isSwitchingRole
                        ? const CircularProgressIndicator(
                      color: Color(0xFF8B7355),
                    )
                        : IconButton(
                      onPressed: () => _showRoleSwitchDialog(context),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4B996), Color(0xFF8B7355)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.change_circle_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ===== CARD TÍCH ĐIỂM =====
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 10),
            //   child: Container(
            //     padding: const EdgeInsets.all(20),
            //     decoration: BoxDecoration(
            //       gradient: const LinearGradient(
            //         colors: [Color(0xFFD4B996), Color(0xFF8B7355)],
            //         begin: Alignment.topLeft,
            //         end: Alignment.bottomRight,
            //       ),
            //       borderRadius: BorderRadius.circular(20),
            //       boxShadow: [
            //         BoxShadow(
            //           color: const Color(0xFF8B7355).withOpacity(0.3),
            //           blurRadius: 15,
            //           offset: const Offset(0, 5),
            //         ),
            //       ],
            //     ),
            //     child: Row(
            //       children: [
            //         Container(
            //           padding: const EdgeInsets.all(12),
            //           decoration: BoxDecoration(
            //             color: Colors.white.withOpacity(0.2),
            //             borderRadius: BorderRadius.circular(15),
            //           ),
            //           child: const Icon(
            //             Icons.workspace_premium,
            //             size: 32,
            //             color: Colors.white,
            //           ),
            //         ),
            //         const SizedBox(width: 16),
            //         const Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 "Chương trình tích điểm",
            //                 style: TextStyle(
            //                   fontSize: 16,
            //                   fontWeight: FontWeight.w700,
            //                   color: Colors.white,
            //                 ),
            //               ),
            //               SizedBox(height: 5),
            //               Text(
            //                 "Tích điểm mỗi lần sử dụng dịch vụ. Nâng hạng thành viên để nhận nhiều ưu đãi hơn!",
            //                 style: TextStyle(
            //                   fontSize: 13,
            //                   color: Colors.white70,
            //                   height: 1.4,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         )
            //       ],
            //     ),
            //   ),
            // ),

            // const SizedBox(height: 25),

            // ===== MENU CHÍNH =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Tài khoản của tôi",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B7355),
                        ),
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    Icons.person_outline,
                    "Thông tin cá nhân",
                    "screen",
                    CustomerRouterConfig.updateProfile,
                    color: const Color(0xFF8B7355),
                  ),
                  // _buildMenuTile(
                  //   Icons.history,
                  //   "Lịch sử giao dịch",
                  //   "screen",
                  //   "",
                  //   color: const Color(0xFF8B7355),
                  // ),
                  // _buildMenuTile(
                  //   Icons.spa,
                  //   "Dịch vụ đã dùng",
                  //   "screen",
                  //   "",
                  //   color: const Color(0xFF8B7355),
                  // ),
                  _buildMenuTile(
                    Icons.favorite_border,
                    "Kỹ thuật viên yêu thích",
                    "screen",
                    CustomerRouterConfig.listLike,
                    color: const Color(0xFF8B7355),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== MENU HỖ TRỢ =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Hỗ trợ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B7355),
                        ),
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    Icons.help_outline,
                    "Trung tâm hỗ trợ",
                    "web",
                    AppConfig.urlSupport,
                    color: const Color(0xFF8B7355),
                  ),
                  _buildMenuTile(
                    Icons.privacy_tip_outlined,
                    "Chính sách bảo mật",
                    "web",
                    AppConfig.urlPrivacy,
                    color: const Color(0xFF8B7355),
                  ),
                  _buildMenuTile(
                    Icons.description_outlined,
                    "Điều khoản dịch vụ",
                    "web",
                    AppConfig.urlTerm,
                    color: const Color(0xFF8B7355),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ===== NÚT ĐĂNG XUẤT =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 16),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout, size: 22),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget từng menu row
  Widget _buildMenuTile(
      IconData icon,
      String text,
      String type,
      String route, {
        Color color = Colors.black87,
        bool isLogout = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if(type == "web") {
            launchUrl(Uri.parse(route));
          } else {
            if (route.isNotEmpty)  context.go(route);
          };
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isLogout ? Colors.red : color,
                  ),
                ),
              ),
              if (route.isNotEmpty)
                Icon(
                  Icons.chevron_right,
                  color: color.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}