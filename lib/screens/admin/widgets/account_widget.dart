import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';

import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/realtime_service.dart';

import '../../../helper/snackbar_helper.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});
  @override
  _AccountTabState createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final UserService userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  late RealtimeService _realtimeService;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  String searchQuery = '';
  String roleFilter = 'ktv';
  String statusFilter = 'all';
  bool showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _realtimeService = RealtimeService(
      context: context,
      onUserStatusUpdate: (data) {
        if (!mounted) return;
        setState(() {
          _handleRealtimeUserStatusUpdate(data);
        });
      },
    );
    _realtimeService.connect();
  }

  void _handleRealtimeUserStatusUpdate(Map<String, dynamic> data) {
    final String userId = data['userId'];
    final bool status = data['status'];

    final int index = users.indexWhere((user) => user['_id'] == userId);
    if (index != -1) {
      setState(() {
        users[index]['status'] = status ? 'active' : 'inactive';
        _applyFilters();
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await userService.getAllUserService();
      if (response['success']) {
        setState(() {
          users = List<Map<String, dynamic>>.from(response['data']);
          _applyFilters();
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    filteredUsers = users.where((user) {
      final matchesSearch = user['phone'].toString().contains(searchQuery) ||
          (user['technician']?['fullName']?.toString() ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (user['fullname']?.toString() ?? '').toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesRole = false;
      if (roleFilter == 'empty') {
        matchesRole = user['roles'] == 'ktv' && (user['technician'] == null || user['technician'].isEmpty);
      } else if (roleFilter == 'ktv') {
        matchesRole = user['roles'] == 'ktv' && user['technician'] != null && user['technician'].isNotEmpty;
      } else {
        matchesRole = user['roles'] == roleFilter;
      }

      final matchesStatus = statusFilter == 'all' || user['status'] == statusFilter;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void _showChangePasswordDialog(String userId) {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('🔒 Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureNewPassword = !obscureNewPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => obscureConfirmPassword = !obscureConfirmPassword);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();

                  if (newPassword.isEmpty || confirmPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mật khẩu xác nhận không khớp')),
                    );
                    return;
                  }

                  try {
                    final response = await userService.changePasswordUserService({
                      'userId': userId,
                      'newPassword': newPassword,
                    });

                    Navigator.pop(context);
                    if (response['success']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đổi mật khẩu thành công')),
                      );
                      _loadUsers();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(response['message'] ?? 'Có lỗi xảy ra')),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Xác nhận'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _toggleUserStatus(String id, bool currentStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
        content: Text(currentStatus
            ? 'Bạn có chắc chắn muốn khóa tài khoản này?'
            : 'Bạn có chắc chắn muốn mở khóa tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await userService.lockOrUnlockUserService(id, {'isActive': !currentStatus});
        _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentStatus
              ? 'Đã khóa tài khoản thành công'
              : 'Đã mở khóa tài khoản thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra, vui lòng thử lại')),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa người dùng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await userService.deleteUserService(userId);
        _loadUsers();
        SnackbarHelper.showSuccess(context, 'Đã xóa người dùng thành công');
      } catch (e) {
        SnackbarHelper.showError(context, 'Có lỗi xảy ra, vui lòng thử lại');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchSection(),
          if (showFilters) _buildFilterSection(),
          _buildUserListSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo số điện thoại hoặc tên',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: Colors.blue,
            ),
            onPressed: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
            tooltip: showFilters ? 'Ẩn bộ lọc' : 'Hiện bộ lọc',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: roleFilter,
                  decoration: InputDecoration(
                    labelText: 'Vai trò',
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ColorConfig.secondary, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 1.5),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                  items: const [
                    DropdownMenuItem(value: 'ktv', child: Text('Kỹ thuật viên')),
                    DropdownMenuItem(value: 'empty', child: Text('Tài khoản trống')),
                    DropdownMenuItem(value: 'quanly', child: Text('Đầu bắn tour')),
                    DropdownMenuItem(value: 'admin', child: Text('Boss (Admin)')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      roleFilter = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Trạng thái',
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ColorConfig.secondary, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.amber.shade700, width: 1.5),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                    DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                    DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      statusFilter = value!;
                      _applyFilters();
                    });
                  },
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserListSection() {
    return Expanded(
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredUsers.isEmpty
          ? const Center(child: Text('Không có người dùng nào phù hợp'))
          : ListView.builder(
        itemCount: filteredUsers.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final hasTechnician = user['technician'] != null && (user['technician']).isNotEmpty;
          final technician = hasTechnician ? (user['technician']) : null;

          final avatarUrl = hasTechnician &&
              technician?['avatar']?['url'] != null
              ? FormatHelper.formatImageUrl(
              technician!['avatar']['url'] ?? '')
              : null;

          return GestureDetector(
            onTap: () => _showUserDetails(user),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + viền theo trạng thái
                  Container(
                    padding: const EdgeInsets.all(2), // khoảng cách viền
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user['status'] == 'active' ? Colors.green : Colors.grey[300]!,
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[100],
                      backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null
                          ? Icon(Icons.person, size: 30, color: ColorConfig.secondary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Nội dung bên phải
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (user['roles'] == 'ktv')
                                    Text(
                                      technician?['fullName'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['phone'] ?? '',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  if (hasTechnician) ...[
                                    const SizedBox(height: 4),
                                  ] else if (user['roles'] == 'quanly') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      user['fullname'] ?? 'Không có tên',
                                      style: TextStyle(color: ColorConfig.primary),
                                    )
                                  ] else if (user['roles'] == 'admin') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quản lý',
                                      style: TextStyle(color: ColorConfig.primary),
                                    )
                                  ]
                                ],
                              ),
                            ),
                            // 👉 Đã bỏ Container trạng thái ở đây
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Các nút hành động
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.key),
                              tooltip: 'Đổi mật khẩu',
                              onPressed: () {
                                _showChangePasswordDialog(user['_id']);
                              },
                            ),
                            if (user['roles'] == 'ktv' && user['technician'] != null) ...[
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Chỉnh sửa thông tin',
                                onPressed: () async {
                                  final result = await context.push(
                                    '/edit-technician',
                                    extra: user,
                                  );
                                  if (result == true) {
                                    _loadUsers();
                                  }
                                },
                              )
                            ],
                            if (user['roles'] != 'admin')
                              IconButton(
                                icon: Icon(
                                  user['isActive'] ? Icons.lock_open : Icons.lock,
                                  color:
                                  user['isActive'] ? Colors.green : Colors.red,
                                ),
                                tooltip: user['isActive']
                                    ? 'Khoá tài khoản'
                                    : 'Mở khóa tài khoản',
                                onPressed: () =>
                                    _toggleUserStatus(user['_id'], user['isActive']),
                              ),
                            if (user['roles'] != 'admin')
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteUser(user['_id']),
                                tooltip: 'Xóa tài khoản',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );

        },
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserDetailWidget(user: user),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class UserDetailWidget extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserDetailWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool hasTechnician = user['technician'] != null && user['technician'].isNotEmpty;
    final technician = hasTechnician ? user['technician'] : null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiết tài khoản',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  user['roles'] == 'ktv' && technician != null ? Center(
                    child: GestureDetector(
                      onTap: () {
                        final imageUrl = technician!['avatar']['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenSingleImageViewer(imageUrl: FormatHelper.formatImageUrl(imageUrl)),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: hasTechnician && technician?['avatar'] != null ? NetworkImage(FormatHelper.formatImageUrl(technician!['avatar']['url'] ?? '')) : null,
                        child: hasTechnician && technician?['avatar'] == null ? const Icon(Icons.person, size: 50) : null,
                      ),
                    ),
                  ) : const SizedBox(),
                  const SizedBox(height: 16),
                  if (user['roles'] == 'quanly' || user['roles'] == 'admin') ...[
                    Center(
                      child: Text(
                        user['roles'] == 'quanly' ? user['fullname'] : 'Quản trị viên - Admin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (user['roles'] == 'ktv' && technician == null) ...[
                    Center(
                      child: Text(
                        'Tài khoản được đăng ký với quyền kỹ thuật viên nhưng chưa tạo hồ sơ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 10),
                  _buildCopyableDetailRow(context, 'Số điện thoại', user['phone']),
                  const Divider(),

                  _buildCopyableDetailRow(context, 'Mật khẩu', user['password']),

                  if (hasTechnician) ...[
                    // const SizedBox(height: 16),
                    // const Text(
                    //   'Thông tin Kỹ thuật viên',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.bold,
                    //   ),
                    // ),
                    const Divider(),
                    _buildDetailRow('Tên đầy đủ', technician?['fullName']),
                    const Divider(),

                    _buildDetailRow('Tỉnh/Thành phố làm việc', technician?['province']),
                    const Divider(),

                    _buildListDetail('Quận/Huyện làm việc', technician?['districts']),
                    const Divider(),

                    _buildDetailRow('Địa chỉ', technician?['address']),
                    const Divider(),

                    _buildDetailRow('Kinh nghiệm', technician?['experience']),
                    const Divider(),

                    _buildDetailRow('Phê duyệt', technician?['isActive'] == false ? 'Chưa duyệt' : 'Đã duyệt'),
                    const Divider(),

                    if (technician?['images'] != null &&
                        (technician!['images'] as List).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Hình ảnh',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (technician['images'] as List).length,
                          itemBuilder: (context, index) {
                            final image = (technician['images'] as List)[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => _showFullScreenImages(context, technician['images'], index),
                                child: Image.network(
                                  FormatHelper.formatImageUrl(image['url'] ?? ''),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildListDetail(String label, List<dynamic>? items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (items == null || items.isEmpty)
            const Text('N/A')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) => Text('- $item')).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(BuildContext context, String label, String? value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Copy $label',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value ?? ''));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Đã copy $label")),
            );
          },
        ),
      ],
    );
  }
}