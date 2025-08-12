import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/format_helper.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final UserService userService = UserService();

  Map<String, dynamic>? technicianData;
  Map<String, dynamic>? inforLogin;
  bool isLoading = true;
  bool isUpdating = false;
  bool isTechnicianActive = false; // true: hồ sơ đã được duyệt
  bool isProfileActive = false; // true: hồ sơ đang hoạt động
  String role = '';
  String statusAccount = ''; // online/offline status
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    final prefs = await SharedPreferences.getInstance();
    role = prefs.getString('role') ?? 'ktv';
    inforLogin = jsonDecode(prefs.getString('inforUserLogin') ?? '{}');
    isTechnicianActive = prefs.getString('isTechnicianActive') == 'true' ? true : false;
    isProfileActive = prefs.getString('isTechnicianActive') == 'true' ? true : false;
    statusAccount = prefs.getString('statusAccount') ?? 'inactive';
    try {
      final response = await userService.loadDetailUserService();
      if (response['success'] == true) {
        setState(() async {
          userData = response['data'];
          technicianData = userData?['technician'];
          isLoading = false;
          // statusAccount = userData!['status'] ?? 'inactive';

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

  // Future<void> loadTechnicianData() async {
  //   setState(() => isLoading = true);
  //   final prefs = await SharedPreferences.getInstance();
  //   // final technician = prefs.getString('technician');
  //   //
  //   // print("Data Technician: $technician");
  //
  //   // role = prefs.getString('role') ?? 'user';
  //   // inforLogin = jsonDecode(prefs.getString('inforUserLogin') ?? '{}');
  //   // isTechnicianActive = prefs.getString('isTechnicianActive') == 'true' ? true : false;
  //
  //   if (technician != null) {
  //     technicianData = jsonDecode(technician);
  //
  //     // Format data
  //     technicianData!['avatarUrl'] = FormatHelper.formatImageUrl(technicianData!['avatar']?['url']);
  //     technicianData!['fullname'] = technicianData!['fullName'];
  //     technicianData!['role'] = inforLogin!['role'] ?? 'ktv';
  //
  //     isProfileActive = prefs.getString('isTechnicianActive') == 'true' ? true : false;
  //     statusAccount = technicianData!['status'] ?? 'inactive';
  //   } else {
  //     isTechnicianActive = false;
  //     isProfileActive = false;
  //     statusAccount = 'inactive';
  //   }
  //
  //   setState(() => isLoading = false);
  // }

  Future<void> toggleUserStatus() async {
    if (technicianData == null || !isTechnicianActive) return;

    final newStatus = statusAccount == 'active' ? 'inactive' : 'active';

    setState(() => isUpdating = true);
    final response = await userService.changeStatusUserService({
      'status': newStatus,
    });

    if (response['success'] == true) {
      setState(() {
      // final prefs = await SharedPreferences.getInstance();
        statusAccount = response['data']['status'];
        technicianData!['status'] = statusAccount;
        isUpdating = false;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('technician', jsonEncode(technicianData));
      await prefs.setString('statusAccount', response['data']['status']);
      // await prefs.setString('statusAccount', jsonEncode(response['data']));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã chuyển sang trạng thái: ${newStatus == 'inactive' ? 'Offline' : 'Online'}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => isUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thay đổi thất bại: ${response['message'] ?? 'Lỗi không xác định'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> editTechnicianProfile() async {
    if (!isTechnicianActive) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa hồ sơ'),
        content: const Text('Chức năng chỉnh sửa hồ sơ sẽ được triển khai sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    if (!isTechnicianActive) return 'Hồ sơ chưa được duyệt';
    if (!isProfileActive) return 'Hồ sơ tạm ngừng hoạt động';
    return statusAccount == 'active' ? 'Online' : 'Offline';
  }

  Color _getStatusColor() {
    if (!isTechnicianActive) return Colors.orange;
    if (!isProfileActive) return Colors.grey;
    return statusAccount == 'active' ? Colors.green : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: _loadUserDetail,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // const Text(
          //   'Thông tin kỹ thuật viên',
          //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          // ),
          const SizedBox(height: 24),

          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: technicianData!['avatar']['url'] != null
                    ? NetworkImage(FormatHelper.formatImageUrl(technicianData!['avatar']['url']))
                    : const AssetImage('lib/assets/images/avatar_placeholder.png')
                as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      technicianData?['fullName'] ?? 'Không có tên',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inforLogin?['phone'] ?? 'Không rõ',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (isTechnicianActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Chuyển trạng thái online/offline', style: TextStyle(fontSize: 16)),
                isUpdating
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Switch(
                  value: statusAccount == 'active',
                  onChanged: isProfileActive ? (_) => toggleUserStatus() : null,
                ),
              ],
            )
          else
            const Text(
              'Hồ sơ chưa được duyệt',
              style: TextStyle(fontSize: 16, color: Colors.orange),
            ),
          const Divider(height: 32),

          // Thông tin bổ sung
          if (technicianData != null) ...[
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Địa chỉ hoạt động: ${technicianData!['commune']}, ${technicianData!['district']}, ${technicianData!['province']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kinh nghiệm
            Row(
              children: [
                const Icon(Icons.work, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Kinh nghiệm: ${technicianData!['experience'] ?? 'Không rõ'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mô tả kinh nghiệm
            Row(
              children: [
                const Icon(Icons.description, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mô tả: ${technicianData!['experienceDescription'] ?? 'Không có mô tả'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bio
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bio: ${technicianData!['bio'] ?? 'Không có bio'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isTechnicianActive)
              ElevatedButton.icon(
                onPressed: () {
                  context.go("/user-edit-technician");
                },
                icon: const Icon(Icons.edit),
                label: const Text('Chỉnh sửa hồ sơ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 16),

            if (isTechnicianActive)
              ElevatedButton.icon(
                onPressed: () {
                  context.go('');
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm hồ sơ người quen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ],
      ),
    );
  }
}