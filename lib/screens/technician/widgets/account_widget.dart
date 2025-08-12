
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/auth_service.dart';

import '../../../helper/full_screen_single_image.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
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
        formatImageUrl: FormatHelper.formatImageUrl,
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
        SnackbarHelper.showSuccess(context, "Đăng xuất thành công");

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
            child: const Text("Hủy"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Đăng xuất"),
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
                    builder: (_) => FullScreenSingleImageViewer(imageUrl: FormatHelper.formatImageUrl(avatarUrl)),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(FormatHelper.formatImageUrl(avatarUrl)),
              ),
            ),
          // Button Đăng xuất
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
          // _buildInfoTile('Họ tên (tài khoản)', user?['fullname']),
          _buildInfoTile('Số điện thoại', user?['phone']),
          _buildInfoTile('Vai trò', user?['roles'] == 'ktv' ? 'Kỹ thuật viên' : user?['roles']),
          _buildInfoTile('Trạng thái', user?['status'] == 'active' ? 'Đang hoạt động' : 'Bị khóa'),

          const Divider(height: 32),
          _buildInfoTile('Tên kỹ thuật viên', technician?['fullName']),
          _buildInfoTile('Khu vực làm việc',
              'Địa chỉ 1: ${technician?['address'] ?? ''}\nĐịa chỉ 2: ${technician?['commune'] ?? ''}, ${technician?['district'] ?? ''}, ${technician?['province'] ?? ''}'),
          _buildInfoTile('Kinh nghiệm', technician?['experience']),
          _buildInfoTile('Mô tả thêm kinh nghiệm', technician?['experienceDescription']),
          _buildInfoTile('Mô tả cá nhân', technician?['bio']),
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
                  final imageUrl = FormatHelper.formatImageUrl(images[index]['url']);
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
          ],
        ],
      ),
    );
  }
}
