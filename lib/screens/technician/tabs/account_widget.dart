import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/app_config.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/handlers/auth_response_handler.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/shared_preferences_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/user_provider.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/routes/config/global_router_config.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/screens/components/wallet_balance_section.dart';
import 'package:spa_app/screens/widgets/role_switcher_card.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';

import '../../../storage/index.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with SingleTickerProviderStateMixin {

  final UserService userService = UserService();
  final AuthService authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool _isRefreshing = false;

  bool _isSwitchingRole = false;
  bool _isLoading = false;
  String _errorMessage = '';
  int nowBalance = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  String rolesActive = '';
  List<String> roles = [];
  bool get isAdmin => AppConfig.adminPhone.contains(userData?['user']['phone']);
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _loadUserDetail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBalanceNow();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalanceNow() async {
    final provider = context.read<UserProvider>();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await provider.loadBalanceUser();
      nowBalance = provider.nowBalance;

      setState(() {
        nowBalance = nowBalance ?? 0;
        _isLoading = false;
      });

      if (!_fadeCtrl.isCompleted) _fadeCtrl.forward();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error get now balance: $e');
    }
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadBalanceNow();
      });
      if (mounted) {
        SnackBarHelper.showSuccess(context, "Đã cập nhật thông tin");
      }

    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Cập nhật thất bại: $e');
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
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
        title: Row(
          children: [
            Icon(Icons.change_circle_rounded, color: ColorConfig.secondary),
            const SizedBox(width: 10),
            Text(
              "Chuyển đổi vai trò",
              style: TextStyle(
                color: ColorConfig.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          "Bạn muốn chuyển sang vai trò khách hàng?\nSau khi chuyển đổi, bạn cần đăng nhập lại bằng số điện thoại này.",
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
              backgroundColor: ColorConfig.secondary,
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

  Future<void> _changeRole() async {
    try {
      setState(() {
        _isSwitchingRole = true;
      });

      final response = await authService.switchRoleAccount({
        "roleChangeTo": "customer",
      });

      await SharedPreferencesHelper.logOut();

      await AuthResponseHandler.handleLoginResponse(
        context: context,
        response: response,
      );

      // if (response['success'] == true) {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: const Text(
      //         "Đã chuyển đổi vai trò thành công. Vui lòng đăng nhập lại!",
      //         style: TextStyle(color: Colors.white),
      //       ),
      //       backgroundColor: Colors.green,
      //       duration: const Duration(seconds: 3),
      //       behavior: SnackBarBehavior.floating,
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(10),
      //       ),
      //     ),
      //   );
      //   await _logout();
      //
      // } else {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: const Text(
      //         "Có lỗi xảy ra khi chuyển đổi vai trò",
      //         style: TextStyle(color: Colors.white),
      //       ),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
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

  Future<void> _loadUserDetail() async {
    // await SharedPreferencesHelper.listAllKeyValue();
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

    try {
      final response = await userService.loadDetailUserService();
      // appLog("${response}");

      if (response['success'] == true) {
        setState(() {
          userData = response['data'];
          isLoading = false;
          rolesActive = rolesActiveStr;
          roles = rolesList;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Lỗi load thông tin chi tiết người dùng: $e");
    }
  }

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
      default:
        return roleKey;
    }
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Không có',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // final response = await authService.logoutService({});
    try {
      await SharedPreferencesHelper.logOut();
      // if (response['success'] == true || response['status'] == "success") {
        context.go(GlobalRouterConfig.loginOTP);
      // } else {
      //   SnackBarHelper.showError(context, "Lỗi đăng xuất");
      // }
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();
    } catch(e) {
      appLog('Error: $e');
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
            child: const Text("Hủy", style: TextStyle(color: Colors.grey),),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Đăng xuất", style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await _logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: ColorConfig.white
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? ColorConfig.secondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? ColorConfig.secondary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor ?? ColorConfig.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // appLog("$isAdmin");
    // appLog("$roles");

    final user = userData?['user'];
    final technician = userData?['technician'];

    final avatarUrl = technician?['avatar']?['url'];
    final images = technician?['images'] ?? [];

    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: ColorConfig.primary,
        backgroundColor: ColorConfig.white,
        strokeWidth: 2,
        child: FadeTransition(
          opacity: _fadeAnim,
          child:
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 130,
                pinned: true,
                backgroundColor: ColorConfig.secondary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorConfig.secondary,
                          ColorConfig.secondary.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: () {
                                if (avatarUrl != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenSingleImageViewer(
                                        imageUrl: FormatHelper.formatNetworkImageUrl(avatarUrl),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 38,
                                  backgroundColor: Colors.white,
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(
                                    FormatHelper.formatNetworkImageUrl(avatarUrl),
                                  )
                                      : null,
                                  child: avatarUrl == null
                                      ? Icon(
                                    Icons.person,
                                    size: 38,
                                    color: ColorConfig.secondary.withOpacity(0.5),
                                  )
                                      : null,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name + Role
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          technician?['fullName'] ?? '---',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: const Text(
                                          'KTV',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Phone
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.phone_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          user?['phone'] ?? 'Chưa có số điện thoại',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Sử dụng widget RoleSwitcherCard đã tách
              if (isAdmin && roles.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
                    child: RoleSwitcherCard(
                      roles: roles,
                      activeRole: rolesActive,
                      onSwitchRole: _handleSwitchRole,
                      isSwitching: isLoading,
                    ),
                  ),
                ),

              // Nội dung chính
              SliverPadding(
                padding: const EdgeInsets.only(left: 20, top: 5, right: 20, bottom: 10 ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Container(
                      child: WalletBalanceSection(
                        balance: nowBalance,
                        // onTapDeposit: () {
                        //   context.go(CustomerRouterConfig.choosePackage);
                        // },
                        onTapWithdraw: () {
                          context.push(TechnicianRouterConfig.createRequestWithdraw);
                        },
                      ),
                    ),

                    const SizedBox(height: 10),
                      Column(
                        children: [
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Cập nhật thông tin',
                            onTap: () {
                              context.push(TechnicianRouterConfig.updateProfileTechnician);
                            },
                          ),
                          const SizedBox(height: 4),
                          _buildActionButton(
                            icon: Icons.spa_outlined,
                            label: 'Các dịch vụ cung cấp',
                            onTap: () {
                              context.go(TechnicianRouterConfig.updateTechnicianService);
                            },
                          ),
                          // const SizedBox(height: 4),
                          // _buildActionButton(
                          //   icon: Icons.bar_chart,
                          //   label: 'Thống kê doanh thu',
                          //   onTap: () {
                          //     context.go(TechnicianRouterConfig.statistical);
                          //   },
                          // ),
                        ],
                      ),

                      const SizedBox(height: 10),


                    // Các nút hành động
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (roles.contains('customer'))...[
                            _buildMenuItem(
                              icon: Icons.swap_horiz,
                              label: 'Chuyển vai trò khách hàng',
                              onTap: () => _showRoleSwitchDialog(context),
                            ),
                            const Divider(height: 1, indent: 52),

                          ],
                          _buildMenuItem(
                            icon: Icons.logout,
                            label: 'Đăng xuất',
                            onTap: () => _showLogoutDialog(context),
                            iconColor: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Về Serene Spa
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Về Serene Spa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            label: 'Trung tâm hỗ trợ',
                            onTap: () {
                              // TODO: Chuyển đến trung tâm hỗ trợ
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Chính sách bảo mật',
                            onTap: () {
                              // TODO: Chuyển đến chính sách bảo mật
                            },
                          ),
                          _buildMenuItem(
                            icon: Icons.description_outlined,
                            label: 'Điều khoản dịch vụ',
                            onTap: () {
                              // TODO: Chuyển đến điều khoản dịch vụ
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          )
        )
      ),
    );
  }
}