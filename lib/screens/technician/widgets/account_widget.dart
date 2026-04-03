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
      // Có thể xử lý lỗi ở đây
      print("Lỗi load thông tin chi tiết người dùng: $e");
    }
  }

  Widget _buildInfoTile(String title, String? value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(value ?? 'Không có'),
    );
  }

  void _showFullScreenImages(BuildContext context, List<dynamic> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => FullScreenImageViewer(
        images: images,
        initialIndex: initialIndex,
        formatImageUrl: FormatHelper.formatNetworkImageUrl,
      ),
    );
  }

  Future<void> _logout() async {

    final response = await authService.logoutService({});
    try {
      if (response['success'] == true || response['status'] == "success") {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text("Đăng xuất thành công")),
        // );
        // SnackbarHelper.showSuccess(context, "Đăng xuất thành công");

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
              // if (mounted) {
              //   Navigator.of(context).pop();
              //   // context.go('/login');
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     const SnackBar(content: Text("Đăng xuất thành công")),
              //   );
              // }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
      IconData icon,
      String text,
      String route, {
        Color color = Colors.black87,
        bool isLogout = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          if (route.isNotEmpty) {
            context.go(route);
          }
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = userData?['user'];
    final technician = userData?['technician'];

    final avatarUrl = technician?['avatar']?['url'];
    final images = technician?['images'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Thông tin tài khoản',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (avatarUrl != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenSingleImageViewer(imageUrl: FormatHelper.formatNetworkImageUrl(avatarUrl)),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(FormatHelper.formatNetworkImageUrl(avatarUrl)),
              ),
            ),

          // const SizedBox(height: 16),
          // _buildInfoTile('Họ tên (tài khoản)', user?['fullname']),
          // _buildInfoTile('ID', user?['id']),
          _buildInfoTile('Số điện thoại', user?['phone']),
          // _buildInfoTile('Vai trò', user?['roles'] == 'ktv' ? 'Kỹ thuật viên' : user?['roles']),
          // _buildInfoTile('Trạng thái', user?['status'] == 'active' ? 'Đang hoạt động' : 'Bị khóa'),

          const Divider(height: 10),
          _buildInfoTile('Tên kỹ thuật viên', technician?['fullName']),
          _buildInfoTile('Khu vực làm việc',
              'Địa chỉ 1: ${technician?['address'] ?? ''}\nĐịa chỉ 2: ${technician?['province'] ?? ''}'),
          _buildInfoTile('Kinh nghiệm', technician?['experience']),
          // _buildInfoTile('Mô tả thêm kinh nghiệm', technician?['experienceDescription']),
          // _buildInfoTile('Mô tả cá nhân', technician?['bio']),
          // _buildInfoTile('Trạng thái phê duyệt', technician?['isApproved'] == true ? 'Đã duyệt' : 'Chưa duyệt'),

          const SizedBox(height: 16),
          if (images.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Hình ảnh đính kèm',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final imageUrl = FormatHelper.formatNetworkImageUrl(images[index]['url']);
                  return GestureDetector(
                    onTap: () => _showFullScreenImages(context, technician['images'], index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showLogoutDialog(context),
              child: const Text('Đăng xuất'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.secondary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => _showRoleSwitchDialog(context),
              icon: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 20,
              ),
              label: const Text(
                "Chuyển vai trò khách hàng",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 16),

            Divider(height: 10,),
            const SizedBox(height: 16),

            Text("Về Serene Spa", style:  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            const SizedBox(height: 16),
            _buildMenuTile(
              Icons.help_outline,
              "Trung tâm hỗ trợ",
              "",
              color: ColorConfig.secondary,
            ),
            _buildMenuTile(
              Icons.privacy_tip_outlined,
              "Chính sách bảo mật",
              "",
              color: ColorConfig.secondary,
            ),
            _buildMenuTile(
              Icons.description_outlined,
              "Điều khoản dịch vụ",
              "",
              color: ColorConfig.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
