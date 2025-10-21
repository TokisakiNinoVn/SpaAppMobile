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
    // debugPrint("Infor technician: ${widget.user}");
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
              value?.toString() ?? 'Không có',
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
                  value ?? 'Không có',
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
            const Text('Không có')
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

  // Hàm xác định trạng thái tài khoản dựa trên status và lastLogin
  Widget _buildAccountStatus() {
    final userInfo = widget.user['userId'] ?? {};
    final String status = userInfo['status'] ?? 'inactive';
    final String? lastLogin = userInfo['lastLogin'];

    // Nếu đang active
    if (status == 'active') {
      return Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Đang hoạt động',
            style: TextStyle(fontSize: 14),
          ),
        ],
      );
    }

    // Nếu inactive và có lastLogin
    if (lastLogin != null) {
      // final DateTime? lastLoginTime = FormatHelper.formatDateTime(lastLogin) as DateTime?;
      final DateTime lastLoginTime = DateTime.parse(lastLogin);

      if (lastLoginTime != null) {
        // final DateTime now = DateTime.now();
        final Duration difference = DateTime.now().difference(lastLoginTime);
        // final Duration difference = now.difference(lastLoginTime);

        // Nếu thời gian đăng nhập cuối dưới 1 ngày
        if (difference.inDays < 1) {
          String timeAgo;
          if (difference.inHours >= 1) {
            timeAgo = 'Hoạt động ${difference.inHours} tiếng trước';
          } else if (difference.inMinutes >= 1) {
            timeAgo = 'Hoạt động ${difference.inMinutes} phút trước';
          } else {
            timeAgo = 'Hoạt động vừa xong';
          }

          return Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeAgo,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          );
        } else {
          // Nếu quá 1 ngày, hiển thị thời gian cụ thể
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lần cuối đăng nhập:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormatHelper.formatDateTime(lastLogin),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      }
    }

    // Trường hợp không có lastLogin hoặc không xác định được
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Chưa đăng nhập lần nào',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = widget.user['userId'] ?? {};
    final displayName = widget.user['fullName'] ?? userInfo['fullname'] ?? 'Không có tên';

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
                        final imageUrl = widget.user['avatar']?['url'];
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
                        child: widget.user['avatar']?['url'] != null
                            ? Image.network(
                          widget.user['avatar']['url'],
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
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildCopyableDetailRow(context, 'Số điện thoại', userInfo['phone']),
                  const Divider(),

                  if (_role == 'admin') ...[
                    _buildCopyableDetailRow(context, 'Mật khẩu', userInfo['password']),
                    const Divider(),
                  ],

                  // Cập nhật phần hiển thị trạng thái tài khoản
                  if (_role == 'admin') ... [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Trạng thái tài khoản',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildAccountStatus(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],

                  if (_role == 'admin') ... [
                    // _buildCopyableDetailRow(context, 'ID KTV', widget.user['_id']),
                    _buildDetailRow('Tên đầy đủ', widget.user['fullName'] ?? 'Không có'),
                    const Divider(),
                  ],

                  _buildDetailRow(
                    'Năm sinh',
                    widget.user['yearOfBirth']?.toString() ?? 'Không có',
                  ),
                  const Divider(),
                  _buildDetailRow('Địa chỉ', widget.user['address'] ?? 'Không có'),
                  const Divider(),
                  _buildDetailRow('Kinh nghiệm', widget.user['experience'] ?? 'Không có'),
                  const Divider(),
                  _buildListDetail('Dịch vụ', widget.user['services']),
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
                              onTap: () => _showFullScreenImages(
                                context,
                                widget.user['images'],
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}