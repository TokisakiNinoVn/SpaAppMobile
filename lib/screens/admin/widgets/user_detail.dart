import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helper/format_helper.dart';
import '../../../helper/full_screen_list_image.dart';
import '../../../helper/full_screen_single_image.dart';

class UserDetailWidgetAdmin extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserDetailWidgetAdmin({super.key, required this.user});

  @override
  State<UserDetailWidgetAdmin> createState() => _UserDetailWidgetAdminState();
}

class _UserDetailWidgetAdminState extends State<UserDetailWidgetAdmin> {
  String _role = 'unknown';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = (prefs.getString('role') ?? 'unknown').replaceAll('"', '');
    });
  }

  void _showFullScreenImages(
      BuildContext context,
      List<dynamic> images,
      int initialIndex,
      ) {
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
            child: Text(
              value?.toString() ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(
      BuildContext context,
      String label,
      String? value,
      ) {
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
                  value ?? 'N/A',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          tooltip: 'Copy $label',
          onPressed: value != null
              ? () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã sao chép $label')),
            );
          }
              : null,
        ),
      ],
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
              children: items
                  .asMap()
                  .entries
                  .map((entry) => Text('- ${entry.value}'))
                  .toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasTechnician = widget.user['technician'] != null;
    final technician = hasTechnician ? widget.user['technician'] : null;
    final displayName = hasTechnician
        ? (technician?['fullName'] ?? widget.user['fullname'] ?? 'Không có tên')
        : widget.user['fullname'] ?? 'Không có tên';

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
                        final imageUrl = technician?['avatar']?['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenSingleImageViewer(
                              imageUrl: imageUrl,
                            ),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasTechnician && technician?['avatar']?['url'] != null
                            ? Image.network(
                          technician!['avatar']['url'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.person, size: 50),
                              ),
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
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text('role: $_role | type: ${_role.runtimeType}' ),

                  const Divider(height: 32),
                  // User basic info
                  _buildCopyableDetailRow(context, 'Số điện thoại', widget.user['phone']),
                  if (_role == 'admin')
                    _buildCopyableDetailRow(context, 'Mật khẩu', widget.user['password']),
                  if (_role == 'admin')
                    _buildDetailRow(
                      'Trạng thái tài khoản',
                      widget.user['isActive'] == true ? 'Kích hoạt' : 'Không kích hoạt',
                    ),
                  // if (_role == 'admin')
                  //   _buildDetailRow(
                  //     'Trạng thái hoạt động',
                  //     widget.user['status'] == 'active' ? 'Hoạt động' : 'Không hoạt động',
                  //   ),
                  if (_role == 'admin')
                    _buildDetailRow(
                      'Lần đăng nhập cuối',
                      widget.user['lastLogin'] != null
                          ? FormatHelper.formatDateTime(widget.user['lastLogin'])
                          : 'Không có',
                    ),
                  if (_role == 'admin')
                    _buildDetailRow(
                      'Ngày tạo',
                      widget.user['createdAt'] != null
                          ? FormatHelper.formatDateTime(widget.user['createdAt'])
                          : 'Không có',
                    ),
                  if (_role == 'admin')
                    _buildDetailRow(
                      'Ngày cập nhật',
                      widget.user['updatedAt'] != null
                          ? FormatHelper.formatDateTime(widget.user['updatedAt'])
                          : 'Không có',
                    ),
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
                    // if (_role == 'admin')
                    //   _buildCopyableDetailRow(context, 'ID KTV', technician?['_id']),
                    _buildDetailRow('Tên đầy đủ', technician?['fullName'] ?? 'N/A'),
                    _buildDetailRow(
                      'Năm sinh',
                      technician?['yearOfBirth']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Tỉnh/Thành phố làm việc',
                      technician?['province'] ?? 'N/A',
                    ),
                    _buildListDetail(
                      'Quận/Huyện làm việc',
                      technician?['districts'],
                    ),
                    _buildDetailRow('Địa chỉ', technician?['address'] ?? 'N/A'),
                    _buildDetailRow('Kinh nghiệm', technician?['experience'] ?? 'N/A'),
                    _buildListDetail('Dịch vụ', technician?['services']),
                    // if (_role == 'admin')
                    //   _buildDetailRow('Giới thiệu', technician?['bio'] ?? 'N/A'),
                    // if (_role == 'admin')
                    //   _buildDetailRow(
                    //     'Trạng thái KTV',
                    //     technician?['isActive'] == true ? 'Kích hoạt' : 'Không kích hoạt',
                    //   ),
                    // if (_role == 'admin')
                    //   _buildDetailRow(
                    //     'Ngày tạo KTV',
                    //     technician?['createdAt'] != null
                    //         ? FormatHelper.formatDateTime(technician['createdAt'])
                    //         : 'Không có',
                    //   ),
                    // if (_role == 'admin')
                    //   _buildDetailRow(
                    //     'Ngày cập nhật KTV',
                    //     technician?['updatedAt'] != null
                    //         ? FormatHelper.formatDateTime(technician['updatedAt'])
                    //         : 'Không có',
                    //   ),
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
                                onTap: () => _showFullScreenImages(
                                  context,
                                  technician['images'],
                                  index,
                                ),
                                child: Image.network(
                                  image['url'] ?? '',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported, size: 50),
                                      ),
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
}