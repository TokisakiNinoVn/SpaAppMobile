import 'package:flutter/material.dart';
import 'package:spa_app/services/user_service.dart';
import '../../../helper/format_helper.dart';
import '../components/full_screen_list_image.dart';
import 'package:flutter/services.dart';

import '../components/full_screen_single_image.dart';


class AccountTab extends StatefulWidget {
  const AccountTab({super.key});
  @override
  _AccountTabState createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final UserService userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  String searchQuery = '';
  String roleFilter = 'ktv';
  String statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
          (user['fullname']?.toString() ?? '').toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = user['roles'] == roleFilter;
      final matchesStatus = user['status'] == statusFilter;
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void _showChangePasswordDialog(String userId) {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi mật khẩu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu mới',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
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
            child: const Text('Xác nhận'),
          ),
        ],
      ),
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
        _loadUsers(); // Refresh the list
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa người dùng thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi xóa người dùng')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          _buildUserListSection(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: roleFilter,
                  decoration: InputDecoration(
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ktv', child: Text('Kỹ thuật viên')),
                    DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: const [
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
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Tìm kiếm theo số điện thoại/tên',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
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
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
                _applyFilters();
              });
            },
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
          final hasTechnician = user['technicians'] != null &&
              (user['technicians'] as List).isNotEmpty;
          final technician = hasTechnician
              ? (user['technicians'] as List).first
              : null;

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
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
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
                                  if (user['role'] == 'ktv')
                                  Text(
                                    user['fullname'] ?? 'Không có tên',
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
                                    Text(
                                      technician?['fullName'] ?? '',
                                      style: const TextStyle(color: Colors.blueGrey),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: user['status'] == 'active'
                                    ? Colors.green[50]
                                    : Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user['status'] == 'active'
                                    ? 'Hoạt động'
                                    : 'Không hoạt động',
                                style: TextStyle(
                                  color: user['status'] == 'active'
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
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
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Chỉnh sửa thông tin',
                              onPressed: () {

                              },
                            ),
                            IconButton(
                              icon: Icon(
                                user['isActive']
                                    ? Icons.lock_open
                                    : Icons.lock,
                                color: user['isActive']
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              tooltip: user['isActive']
                                  ? 'Khoá tài khoản'
                                  : 'Mở khóa tài khoản',
                              onPressed: () => _toggleUserStatus(
                                  user['_id'], user['isActive']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
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
    final hasTechnician = user['technicians'] != null &&
        (user['technicians'] as List).isNotEmpty;
    final technician = hasTechnician
        ? (user['technicians'] as List).first
        : null;

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
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        final imageUrl = technician!['avatar']['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenSingleImageViewer(
                              imageUrl: FormatHelper.formatImageUrl(imageUrl),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: hasTechnician &&
                            technician?['avatar'] != null
                            ? NetworkImage(FormatHelper.formatImageUrl(
                            technician!['avatar']['url'] ?? ''))
                            : null,
                        child: hasTechnician &&
                            technician?['avatar'] == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user['fullname'] ?? 'Không có tên',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildCopyableDetailRow(context, 'Số điện thoại', user['phone']),
                  _buildCopyableDetailRow(context, 'Mật khẩu', user['password']),

                  _buildDetailRow('Vai trò',
                      user['roles'] == 'admin' ? 'Quản trị viên' : 'Kỹ thuật viên'),
                  _buildDetailRow('Trạng thái',
                      user['status'] == 'active' ? 'Hoạt động' : 'Không hoạt động'),
                  _buildDetailRow('Lần đăng nhập cuối', FormatHelper.formatDateTime(user['lastLogin'])),
                  if (hasTechnician) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Thông tin Kỹ thuật viên',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow('Tên đầy đủ', technician?['fullName']),
                    _buildDetailRow('Tỉnh/Thành phố', technician?['province']),
                    _buildDetailRow('Quận/Huyện', technician?['district']),
                    _buildDetailRow('Phường/Xã', technician?['commune']),
                    _buildDetailRow('Địa chỉ', technician?['address']),
                    _buildDetailRow('Kinh nghiệm', technician?['experience']),
                    _buildDetailRow('Mô tả kinh nghiệm', technician?['experienceDescription']),
                    _buildDetailRow('Giới thiệu', technician?['bio']),
                    _buildDetailRow('Đã được phê duyệt',
                        technician?['isApproved'] ? 'Có' : 'Không'),

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
                            final image =
                            (technician['images'] as List)[index];
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