import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';

import 'package:spa_app/services/user_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/services/realtime_service.dart';
import '../../../../helper/snackbar_helper.dart';

class ManagementAccountTechnician extends StatefulWidget {
  const ManagementAccountTechnician({super.key});
  @override
  _ManagementAccountTechnicianState createState() => _ManagementAccountTechnicianState();
}

class _ManagementAccountTechnicianState extends State<ManagementAccountTechnician> {
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

      // Xử lý các loại role filter
      if (roleFilter == 'ktv') {
        // KTV đã được duyệt (có technician và status == true)
        matchesRole = user['rolesActive'] == 'ktv'
            && user['technician'] != null
            && user['technician'].isNotEmpty
            && user['isAcceptHaveApprovalRequest'] == true;

      } else if (roleFilter == 'ktv_pending') {
        // KTV chưa duyệt (có technician và status == false)
        matchesRole = user['rolesActive'] == 'ktv' &&
            user['technician'] != null &&
            user['technician'].isNotEmpty &&
            user['isAcceptHaveApprovalRequest'] == false;
      } else if (roleFilter == 'empty') {
        // Tài khoản trống (chưa tạo hồ sơ technician)
        matchesRole = user['rolesActive'] == 'ktv' && (user['technician'] == null || user['technician'].isEmpty);
      } else if (roleFilter == 'quanly') {
        matchesRole = user['rolesActive'] == 'quanly';
      } else if (roleFilter == 'admin') {
        matchesRole = user['rolesActive'] == 'admin';
      }
      else if (roleFilter == 'customer') {
        matchesRole = user['rolesActive'] == 'customer';
      } else {
        matchesRole = user['rolesActive'] == roleFilter;
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
        SnackBarHelper.showSuccess(context, 'Đã xóa người dùng thành công');
      } catch (e) {
        SnackBarHelper.showError(context, 'Có lỗi xảy ra, vui lòng thử lại');
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bộ lọc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.tune),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Vai trò filter
                  const Text(
                    'Vai trò',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: roleFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'ktv', child: Text('Kỹ thuật viên (đã duyệt)')),
                          DropdownMenuItem(value: 'ktv_pending', child: Text('KTV - chưa duyệt')),
                          DropdownMenuItem(value: 'customer', child: Text('Khách hàng')),
                          DropdownMenuItem(value: 'empty', child: Text('Tài khoản trống')),
                          DropdownMenuItem(value: 'quanly', child: Text('Đầu bắn tour')),
                          DropdownMenuItem(value: 'admin', child: Text('Boss (Admin)')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            roleFilter = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Trạng thái filter
                  const Text(
                    'Trạng thái',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: statusFilter,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                          DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            statusFilter = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nút áp dụng và reset
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              roleFilter = 'ktv';
                              statusFilter = 'all';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Đặt lại'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Khi đóng bottomsheet, cập nhật lại filter
      setState(() {
        _applyFilters();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // title: const Text("Quản lý tài khoản", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          title: const Text("Quản lý tài khoản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_alt_outlined, size: 22),
              color: Colors.black,
              onPressed: _showFilterBottomSheet,
              tooltip: 'Lọc',
            ),
          ]
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildActiveFiltersChips(),
          _buildUserListSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
    );
  }

  Widget _buildActiveFiltersChips() {
    // Chỉ hiển thị chips khi có filter khác mặc định
    bool hasActiveFilters = roleFilter != 'ktv' || statusFilter != 'all';

    if (!hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (roleFilter != 'ktv')
              Chip(
                label: Text(_getRoleFilterLabel(roleFilter)),
                onDeleted: () {
                  setState(() {
                    roleFilter = 'ktv';
                    _applyFilters();
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: Colors.blue.shade50,
              ),
            if (statusFilter != 'all')
              Chip(
                label: Text(_getStatusFilterLabel(statusFilter)),
                onDeleted: () {
                  setState(() {
                    statusFilter = 'all';
                    _applyFilters();
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: Colors.green.shade50,
              ),
          ],
        ),
      ),
    );
  }

  String _getRoleFilterLabel(String role) {
    switch (role) {
      case 'ktv':
        return 'Kỹ thuật viên (đã duyệt)';
      case 'ktv_pending':
        return 'KTV - chưa duyệt';
      case 'empty':
        return 'Tài khoản trống';
      case 'quanly':
        return 'Đầu bắn tour';
      case 'admin':
        return 'Boss (Admin)';
      default:
        return role;
    }
  }

  String _getStatusFilterLabel(String status) {
    switch (status) {
      case 'active':
        return 'Hoạt động';
      case 'inactive':
        return 'Không hoạt động';
      default:
        return status;
    }
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

          // Kiểm tra trạng thái duyệt của KTV
          final bool isTechnicianApproved = hasTechnician && technician?['isActive'] == true;
          final bool isTechnicianPending = hasTechnician && technician?['isAcceptHaveApprovalRequest'] == true;

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
                    padding: const EdgeInsets.all(2),
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
                      // avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      avatarUrl != null ? NetworkImage(FormatHelper.formatNetworkImageUrl(avatarUrl)) : null,
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
                                  if (user['rolesActive'] == 'ktv')
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            technician?['fullName'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isTechnicianPending)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Chờ duyệt',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['phone'] ?? '',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  if (hasTechnician) ...[
                                    const SizedBox(height: 4),
                                  ] else if (user['rolesActive'] == 'quanly') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      user['fullname'] ?? 'Không có tên',
                                      style: TextStyle(color: ColorConfig.primary),
                                    )
                                  ] else if (user['rolesActive'] == 'admin') ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quản lý',
                                      style: TextStyle(color: ColorConfig.primary),
                                    )
                                  ]
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Các nút hành động
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // IconButton(
                            //   icon: const Icon(Icons.history),
                            //   tooltip: 'Lịch sử hoạt động',
                            //   onPressed: () {
                            //     _showChangePasswordDialog(user['_id']);
                            //   },
                            // ),
                            IconButton(
                              icon: const Icon(Icons.key),
                              tooltip: 'Đổi mật khẩu',
                              onPressed: () {
                                _showChangePasswordDialog(user['_id']);
                              },
                            ),
                            if (user['rolesActive'] == 'ktv' && user['technician'] != null) ...[
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: 'Chỉnh sửa thông tin',
                                onPressed: () async {
                                  final result = await context.push(
                                    AdminRouterConfig.editTechnician,
                                    extra: user,
                                  );
                                  if (result == true) {
                                    _loadUsers();
                                  }
                                },
                              )
                            ],
                            if (user['rolesActive'] != 'admin')
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
                            if (user['rolesActive'] != 'admin')
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
    final bool isTechnicianPending = hasTechnician && technician?['isActive'] == false;

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
                  user['rolesActive'] == 'ktv' && technician != null ? Center(
                    child: GestureDetector(
                      onTap: () {
                        final imageUrl = technician!['avatar']['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenSingleImageViewer(imageUrl: FormatHelper.formatNetworkImageUrl(imageUrl)),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: hasTechnician && technician?['avatar'] != null ? NetworkImage(FormatHelper.formatNetworkImageUrl(technician!['avatar']['url'] ?? '')) : null,
                        child: hasTechnician && technician?['avatar'] == null ? const Icon(Icons.person, size: 50) : null,
                      ),
                    ),
                  ) : const SizedBox(),
                  const SizedBox(height: 16),
                  if (user['rolesActive'] == 'quanly' || user['rolesActive'] == 'admin') ...[
                    Center(
                      child: Text(
                        user['rolesActive'] == 'quanly' ? user['fullname'] : 'Quản trị viên - Admin',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else if (user['rolesActive'] == 'ktv' && technician == null) ...[
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

                    _buildDetailRow(
                      'Phê duyệt',
                      isTechnicianPending ? 'Chưa duyệt' : 'Đã duyệt',
                    ),
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
                                  FormatHelper.formatNetworkImageUrl(image['url'] ?? ''),
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