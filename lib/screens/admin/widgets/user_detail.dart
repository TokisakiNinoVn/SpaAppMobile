

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../helper/format_helper.dart';
import '../../../helper/full_screen_list_image.dart';
import '../../../helper/full_screen_single_image.dart';

class UserDetailWidget extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserDetailWidget({super.key, required this.user});
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
  @override
  Widget build(BuildContext context) {
    final bool hasTechnician = user['technician'] != null;
    final technician = hasTechnician ? user['technician'] : null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      height: MediaQuery
          .of(context)
          .size
          .height * 0.8,
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
                        final imageUrl = technician?['avatar']?['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                FullScreenSingleImageViewer(
                                    imageUrl: imageUrl),
                          );
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: hasTechnician && technician?['avatar'] != null
                            ? Image.network(
                          technician!['avatar']['url'] ?? '',
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
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      user['role'] == 'ktv' ? (user['fullName'] ??
                          'Không có tên') : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  _buildCopyableDetailRow(
                      context, 'Số điện thoại', user['phone']),
                  _buildCopyableDetailRow(
                      context, 'Mật khẩu', user['password']),
                  _buildDetailRow('Trạng thái', user['status'] == 'active'
                      ? 'Hoạt động'
                      : 'Không hoạt động'),
                  _buildDetailRow(
                    'Lần đăng nhập cuối',
                    user['lastLogin'] != null ? FormatHelper.formatDateTime(
                        user['lastLogin']) : 'Không có',
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
                    _buildDetailRow('Tên đầy đủ', technician?['fullName']),
                    _buildDetailRow('Tỉnh/Thành phố', technician?['province']),
                    _buildDetailRow('Quận/Huyện', technician?['district']),
                    _buildDetailRow('Địa chỉ', technician?['address']),
                    _buildDetailRow('Kinh nghiệm', technician?['experience']),
                    _buildDetailRow('Giới thiệu', technician?['bio']),
                    _buildDetailRow('Phê duyệt',
                        technician?['isAcceptHaveApprovalRequest'] == true
                            ? 'Đã được phê duyệt'
                            : 'Chưa được phê duyệt'),
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
                                onTap: () =>
                                    _showFullScreenImages(
                                        context, technician['images'], index),
                                child: Image.network(
                                  image['url'] ?? '',
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
  }