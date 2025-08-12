import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/config/theme_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/approval_request_service.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/full_screen_list_image.dart';
import 'package:spa_app/helper/full_screen_single_image.dart';

class ApproveTab extends StatefulWidget {
  const ApproveTab({super.key});

  @override
  _ApproveTabState createState() => _ApproveTabState();
}

class _ApproveTabState extends State<ApproveTab> {
  final ApprovalRequestService approvalRequestService = ApprovalRequestService();
  List<Map<String, dynamic>> approvalRequests = [];
  List<Map<String, dynamic>> filteredRequests = [];
  bool isLoading = true;
  String selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadApprovalRequests();
  }

  Future<void> _loadApprovalRequests() async {
    setState(() => isLoading = true);
    final response = await approvalRequestService.getAllApprovalRequestService();
    print("response: ");
    if (response['success']) {
      setState(() {
        approvalRequests = List<Map<String, dynamic>>.from(response['data']);
        // print("list approvalRequests: $approvalRequests");
        _applyFilter();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      if (selectedFilter == 'all') {
        filteredRequests = approvalRequests;
      } else {
        filteredRequests = approvalRequests
            .where((request) => request['status'] == selectedFilter)
            .toList();
      }
    });
  }

  Future<void> _approveRequest(String id) async {
    setState(() => isLoading = true);
    try {
      final response = await approvalRequestService.approveApprovalRequestService(id, {});
      final isSuccess = response['success'] == true;

      if (isSuccess) {
        setState(() {
          approvalRequests.removeWhere((request) => request['_id'] == id);
          _applyFilter();
          isLoading = false;
        });
        SnackbarHelper.showSuccess(context, 'Yêu cầu đã được phê duyệt thành công');
      } else {
        throw Exception("Phê duyệt thất bại hoặc không thành công.");
      }
    } catch (e) {
      setState(() => isLoading = false);
      SnackbarHelper.showError(context, 'Phê duyệt yêu cầu thất bại: $e');
      print('Phê duyệt yêu cầu thất bại: $e');
    }
  }

  Future<void> _showApproveConfirmDialog(String id) async {
    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text(
                'Xác nhận phê duyệt',
                style: ThemeConfig.appTextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorConfig.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Bạn có chắc chắn muốn phê duyệt yêu cầu này không?',
            style: ThemeConfig.appTextStyle(
              fontSize: 16,
              color: ColorConfig.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Hủy',
                style: ThemeConfig.appTextStyle(
                  color: ColorConfig.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Phê duyệt', style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );

    if (shouldApprove == true) {
      _approveRequest(id);
    }
  }


  void _showRequestDetails(BuildContext context, Map<String, dynamic> request) {
    final isTechnicianRequest = request['technician'] != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5E3C),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Text(
                      isTechnicianRequest ? 'Chi tiết Kỹ thuật viên' : 'Chi tiết Yêu cầu',
                      style: ThemeConfig.appTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ColorConfig.textPrimary)
                  ),
                  const SizedBox(height: 24),
                  if (isTechnicianRequest) ...[
                    GestureDetector(
                      onTap: () {
                        final imageUrl = request['technician']['avatar']?['url'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => FullScreenSingleImageViewer(
                              imageUrl: FormatHelper.formatImageUrl(imageUrl),
                            ),
                          );
                        }
                      },
                      child: Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: request['technician']['avatar']?['url'] != null
                              ? CachedNetworkImageProvider(
                            FormatHelper.formatImageUrl(request['technician']['avatar']['url']),
                          )
                              : null,
                          child: request['technician']['avatar']?['url'] == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildInfoRow('Họ và Tên', isTechnicianRequest
                      ? request['technician']['fullName'] ?? 'Không có'
                      : request['user']['fullname'] ?? 'Không có'),
                  _buildInfoRow('Số điện thoại', request['user']['phone'] ?? 'Không có'),
                  if (isTechnicianRequest) ...[
                    _buildInfoRow(
                      'Địa chỉ',
                      '${request['technician']['province'] ?? ''}, ${request['technician']['district'] ?? ''}, ${request['technician']['commune'] ?? ''}, ${request['technician']['address'] ?? ''}',
                    ),
                    _buildInfoRow('Kinh nghiệm', request['technician']['experience'] ?? 'Không có'),
                    _buildInfoRow('Tiểu sử', request['technician']['bio'] ?? 'Không có'),
                  ],
                  _buildInfoRow('Vai trò', request['user']['roles'] == 'ktv' ? 'Kỹ thuật viên' : 'Quản lý'),
                  _buildInfoRow('Trạng thái', request['status'] == 'approved' ? 'Đã phê duyệt' : 'Chưa phê duyệt'),
                  _buildInfoRow('Ngày gửi', FormatHelper.formatDateTime(request['submittedAt']) ?? 'Không có'),
                  if (isTechnicianRequest) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Hình ảnh',
                      style: ThemeConfig.appTextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ColorConfig.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    (request['technician']['images'] as List<dynamic>?)?.isNotEmpty ?? false
                        ? GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: (request['technician']['images'] as List<dynamic>?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final image = request['technician']['images'][index];
                        final imageUrl = FormatHelper.formatImageUrl(image['url']);
                        return GestureDetector(
                          onTap: () => _showFullScreenImages(context, request['technician']['images'], index),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: ColorConfig.textSecondary,
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.error,
                                  size: 48,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                        : Text(
                        'Không có hình ảnh',
                        style: ThemeConfig.appTextStyle(fontSize: 16, color: ColorConfig.textSecondary)
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Center(
                  //   child: request['status'] != 'approved' ? IconButton(
                  //     onPressed: () => _approveRequest(request['_id']),
                  //     icon: Icon(Icons.check_circle, size: 40, color: Colors.green),
                  //     tooltip: 'Phê duyệt',
                  //   ) : const SizedBox.shrink(),
                  // ),
                  Center(
                    child: request['status'] != 'approved'
                        ? IconButton(
                      onPressed: () => _showApproveConfirmDialog(request['_id']),
                      icon: Icon(Icons.check_circle, size: 40, color: Colors.green),
                      tooltip: 'Phê duyệt',
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
                label,
                style: ThemeConfig.appTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ColorConfig.textPrimary)
            ),
          ),
          Expanded(
            child: Text(
                value,
                style: ThemeConfig.appTextStyle(fontSize: 16, color: ColorConfig.black)
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        //   child: DropdownButtonFormField<String>(
        //     value: selectedFilter,
        //     decoration: InputDecoration(
        //       labelText: 'Lọc theo trạng thái',
        //       labelStyle: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary),
        //       border: OutlineInputBorder(
        //         borderRadius: BorderRadius.circular(12),
        //         borderSide: const BorderSide(color: Color(0xFFD4A373)),
        //       ),
        //       focusedBorder: OutlineInputBorder(
        //         borderRadius: BorderRadius.circular(12),
        //         borderSide: const BorderSide(color: Color(0xFFD4A373), width: 2),
        //       ),
        //     ),
        //     items: [
        //       DropdownMenuItem(
        //         value: 'pending',
        //         child: Text(
        //             'Chưa phê duyệt',
        //             style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)
        //         ),
        //       ),
        //       DropdownMenuItem(
        //         value: 'approved',
        //         child: Text(
        //             'Đã phê duyệt',
        //             style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)
        //         ),
        //       ),
        //       DropdownMenuItem(
        //         value: 'all',
        //         child: Text(
        //             'Tất cả',
        //             style: ThemeConfig.appTextStyle(color: ColorConfig.textPrimary)
        //         ),
        //       ),
        //     ],
        //     onChanged: (value) {
        //       setState(() {
        //         selectedFilter = value!;
        //         _applyFilter();
        //       });
        //     },
        //   ),
        // ),
        Expanded(
          child: isLoading
              ? Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFD4A373),
            ),
          )
              : filteredRequests.isEmpty
              ? Center(
            child: Text(
                'Không tìm thấy yêu cầu phê duyệt',
                style: ThemeConfig.appTextStyle(fontSize: 18, color: ColorConfig.textPrimary)
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: filteredRequests.length,
            itemBuilder: (context, index) {
              final request = filteredRequests[index];
              final isTechnicianRequest = request['technician'] != null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: isTechnicianRequest && request['technician']['avatar']?['url'] != null
                        ? CachedNetworkImageProvider(
                      FormatHelper.formatImageUrl(request['technician']['avatar']['url']),
                    )
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: isTechnicianRequest && request['technician']['avatar']?['url'] == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : !isTechnicianRequest
                        ? const Icon(Icons.person_outline, color: Colors.grey)
                        : null,
                  ),

                  title: Text(isTechnicianRequest ?
                    request['technician']['fullName'] ?? 'Kỹ thuật viên' : request['user']['fullname'] ?? 'Quản lý',
                      style: ThemeConfig.appTextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ColorConfig.textPrimary)
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${request['user']['roles'] == 'ktv' ? 'Kỹ thuật viên' : 'Quản lý'}',
                          style: ThemeConfig.appTextStyle(fontSize: 14, color: ColorConfig.textSecondary)
                      ),
                    ],
                  ),
                  onTap: () => _showRequestDetails(context, request),
                  // trailing: request['status'] != 'approved' ? IconButton(
                  //   onPressed: () => _approveRequest(request['_id']),
                  //   icon: Icon(Icons.check_circle, color: Colors.green, size: 32),
                  //   tooltip: 'Phê duyệt',
                  // ) : null,
                  trailing: request['status'] != 'approved'
                      ? IconButton(
                    onPressed: () => _showApproveConfirmDialog(request['_id']),
                    icon: Icon(Icons.check_circle, color: Colors.green, size: 32),
                    tooltip: 'Phê duyệt',
                  )
                      : null,

                ),
              );
            },
          ),
        ),
      ],
    );
  }
}