import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';

import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/tinhthanh_service.dart';

class ManagementTechnicianTab extends StatefulWidget {
  const ManagementTechnicianTab({super.key});
  @override
  _ManagementTechnicianTabState createState() =>
      _ManagementTechnicianTabState();
}

class _ManagementTechnicianTabState extends State<ManagementTechnicianTab> {
  final TechnicianService technicianService = TechnicianService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _provinceSearchController =
      TextEditingController();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];

  bool isLoading = true;
  String searchQuery = '';
  String? statusFilter;
  bool showProvinceList = false;
  bool showStatusList = false;
  String? selectedProvince;

  bool isProvincesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await technicianService.getListTechnicianCreateByUser();
      if (response['success']) {
        final filteredUsers = List<Map<String, dynamic>>.from(response['data']);

        setState(() {
          users = filteredUsers;
          _applyFilters();
        });
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    filteredUsers =
        users.where((user) {
          final matchesSearch =
              user['phone'].toString().contains(searchQuery) ||
              (user['fullName'].toString() ?? '').toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
          final matchesStatus =
              statusFilter == null || user['status'] == statusFilter;
          final matchesProvince =
              selectedProvince == null ||
              selectedProvince == 'Tất cả' ||
              user['province'] == selectedProvince;
          return matchesSearch && matchesStatus && matchesProvince;
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchSection(),
              Expanded(child: _buildUserListSection()),
            ],
          ),
          if (showProvinceList) _buildProvinceSelectionWidget(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo số điện thoại hoặc tên',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchController.text.isNotEmpty
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
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
                icon: const Icon(Icons.add),
                color: Colors.grey,
                onPressed: () {
                  context.push("/home-technician/add-technician");
                },
                tooltip: 'Thêm hồ sơ mới',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceSelectionWidget() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Chọn tỉnh thành',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        showProvinceList = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _provinceSearchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tỉnh thành',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _provinceSearchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _provinceSearchController.clear();
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListSection() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : filteredUsers.isEmpty
        ? const Center(child: Text('Không có người dùng nào phù hợp'))
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 160 / 190,
            ),
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              final avatarUrl =
                  user['avatar']?['url'] != null
                      ? FormatHelper.formatImageUrl(user['avatar']['url'] ?? '')
                      : null;
              return GestureDetector(
                onTap: () => _showUserDetails(user),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child:
                            avatarUrl != null
                                ? Image.network(
                                  avatarUrl,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                        height: 160,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                                : Container(
                                  height: 160,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (user['status'] == 'active') ...[
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Flexible(
                              child: Text(
                                user['fullName'] ?? 'Không có tên',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
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
      builder:
          (context) => UserDetailWidget(
            user: user,
            onEditSuccess: _loadUsers,
            onDeleteSuccess: _loadUsers,
          ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provinceSearchController.dispose();
    super.dispose();
  }
}

class UserDetailWidget extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEditSuccess;
  final VoidCallback onDeleteSuccess;

  const UserDetailWidget({
    super.key,
    required this.user,
    required this.onEditSuccess,
    required this.onDeleteSuccess,
  });

  @override
  State<UserDetailWidget> createState() => _UserDetailWidgetState();
}

class _UserDetailWidgetState extends State<UserDetailWidget> {
  final TechnicianService _technicianService = TechnicianService();
  bool _isDeleting = false;

  Future<void> _deleteTechnician() async {
    setState(() => _isDeleting = true);
    try {
      final response = await _technicianService.deleteTechnicianCreateByUser(
        widget.user['_id'],
      );

      if (response['success']) {
        if (mounted) {
          Navigator.pop(context); // Đóng bottom sheet
          widget.onDeleteSuccess(); // Reload danh sách
          SnackbarHelper.showSuccess(context, 'Xóa kỹ thuật viên thành công');
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            response['message'] ?? 'Xóa thất bại',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Có lỗi xảy ra: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa kỹ thuật viên này? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _isDeleting ? null : _deleteTechnician,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child:
                  _isDeleting
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiết hồ sơ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                        final imageUrl = widget.user['avatar']?['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder:
                                (_) => FullScreenSingleImageViewer(
                                  imageUrl: FormatHelper.formatImageUrl(
                                    imageUrl,
                                  ),
                                ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            widget.user['avatar'] != null
                                ? Image.network(
                                  FormatHelper.formatImageUrl(
                                    widget.user['avatar']['url'] ?? '',
                                  ),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 100,
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 50),
                                ),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  const SizedBox(height: 16),
                  const Text(
                    'Thông tin Kỹ thuật viên',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildDetailRow('Tên đầy đủ', widget.user['fullName']),
                  _buildDetailRow('Tỉnh/Thành phố', widget.user['province']),
                  _buildDetailRow('Địa chỉ', widget.user['address']),
                  _buildDetailRow('Kinh nghiệm', widget.user['experience']),
                  _buildDetailRow('Giới thiệu', widget.user['bio']),
                  _buildDetailRow(
                    'Tình trạng hồ sơ',
                    widget.user['isActive'] == true
                        ? 'Đã được phê duyệt'
                        : 'Chưa được phê duyệt',
                  ),
                  if (widget.user['images'] != null &&
                      (widget.user['images'] as List).isNotEmpty) ...[
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
                        itemCount: (widget.user['images'] as List).length,
                        itemBuilder: (context, index) {
                          final image = (widget.user['images'] as List)[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap:
                                  () => _showFullScreenImages(
                                    context,
                                    widget.user['images'],
                                    index,
                                  ),
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
                  if (widget.user['isActive'] == true) ...[
                    const SizedBox(height: 16),
                    // nút Chỉnh sửa và nút xóa
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await context.push(
                                '/edit-add-technician',
                                extra: widget.user,
                              );
                              if (result == true) {
                                Navigator.pop(context);
                                widget.onEditSuccess();
                              }
                            },
                            child: const Text('Chỉnh sửa'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showDeleteConfirmationDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Xóa'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImages(
    BuildContext context,
    List<dynamic> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => FullScreenImageViewer(
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
          Expanded(flex: 3, child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }
}
