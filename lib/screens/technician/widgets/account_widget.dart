import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/services/auth_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final UserService userService = UserService();
  final AuthService authService = AuthService();
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool _isSwitchingRole = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
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

      final response = await userService.changeRoleService({});
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

  Future<void> _loadUserDetail() async {
    try {
      final response = await userService.loadDetailUserService();
      if (response['success'] == true) {
        setState(() {
          userData = response['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Lỗi load thông tin chi tiết người dùng: $e");
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
    final response = await authService.logoutService({});
    try {
      if (response['success'] == true || response['status'] == "success") {
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng xuất thất bại")),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch(e) {
      print('Error: $e');
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
              backgroundColor: ColorConfig.secondary,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
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

    final user = userData?['user'];
    final technician = userData?['technician'];

    final avatarUrl = technician?['avatar']?['url'];
    final images = technician?['images'] ?? [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Header với gradient
          SliverAppBar(
            expandedHeight: 200,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
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
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(FormatHelper.formatNetworkImageUrl(avatarUrl))
                                : null,
                            child: avatarUrl == null
                                ? Icon(
                              Icons.person,
                              size: 50,
                              color: ColorConfig.secondary.withOpacity(0.5),
                            )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tên kỹ thuật viên
                      Text(
                        'KTV: ${technician?['fullName'] ?? '---'}' ,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Số điện thoại
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?['phone'] ?? 'Chưa có số điện thoại',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nội dung chính
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Thông tin chi tiết
                Container(
                  padding: const EdgeInsets.all(20),
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
                      _buildInfoRow('Họ và tên', technician?['fullName']),
                      const Divider(height: 1),
                      _buildInfoRow('Số điện thoại', user?['phone']),
                      // const Divider(height: 1),
                      // _buildInfoRow('Email', technician?['email']),
                      // const Divider(height: 1),
                      // _buildInfoRow('Địa chỉ', technician?['address']),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Cập nhật thông tin',
                      onTap: () {
                        context.push('/home-technician/update-profile');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.spa_outlined,
                      label: 'Các dịch vụ cung cấp',
                      onTap: () {
                        context.go('/home-technician/technician-update-service');
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.bar_chart,
                      label: 'Thống kê doanh thu',
                      onTap: () {
                        context.go('/home-technician/technician-update-service');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

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
                      _buildMenuItem(
                        icon: Icons.swap_horiz,
                        label: 'Chuyển vai trò khách hàng',
                        onTap: () => _showRoleSwitchDialog(context),
                      ),
                      const Divider(height: 1, indent: 52),
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
      ),
    );
  }
}