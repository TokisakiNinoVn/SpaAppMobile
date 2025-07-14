import 'package:flutter/material.dart';
import 'package:spa_app/services/approval_request_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../helper/format_helper.dart';
import '../components/full_screen_list_image.dart';
import '../components/full_screen_single_image.dart';

class ApproveTab extends StatefulWidget {
  const ApproveTab({super.key});

  @override
  _ApproveTabState createState() => _ApproveTabState();
}

class _ApproveTabState extends State<ApproveTab> {
  final ApprovalRequestService approvalRequestService = ApprovalRequestService();
  List<Map<String, dynamic>> approvalRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovalRequests();
  }

  Future<void> _loadApprovalRequests() async {
    final response = await approvalRequestService.getAllApprovalRequestService();
    if (response['success']) {
      setState(() {
        approvalRequests = List<Map<String, dynamic>>.from(response['data']);
        isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(String id) async {
    setState(() => isLoading = true);

    final response = await approvalRequestService.approveApprovalRequestService(id, {});

    if (response['success']) {
      setState(() {
        approvalRequests.removeWhere((request) => request['_id'] == id);
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yêu cầu đã được phê duyệt thành công',
            style: GoogleFonts.lora(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFD4A373),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phê duyệt yêu cầu thất bại',
            style: GoogleFonts.lora(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request) {
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
                    'Chi tiết Kỹ thuật viên',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5E3C),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Center(
                  //   child: CircleAvatar(
                  //     radius: 60,
                  //     backgroundImage: CachedNetworkImageProvider(
                  //       FormatHelper.formatImageUrl(request['technicianId']['avatar']['url'] ?? ''),
                  //     ),
                  //     backgroundColor: Colors.grey[200],
                  //     child: request['technicianId']['avatar']['url'] == null
                  //         ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  //         : null,
                  //   ),
                  // ),

                  GestureDetector(
                    onTap: () {
                      final imageUrl = request['technicianId']['avatar']['url'];
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
                        backgroundImage: request['technicianId']['avatar']['url'] != null
                            ? CachedNetworkImageProvider(
                          FormatHelper.formatImageUrl(request['technicianId']['avatar']['url']),
                        )
                            : null,
                        child: request['technicianId']['avatar']['url'] == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildInfoRow('Họ và Tên', request['technicianId']['fullName'] ?? 'Không có'),
                  _buildInfoRow('Số điện thoại', request['technicianId']['userId']['phone'] ?? 'Không có'),
                  _buildInfoRow(
                    'Địa chỉ',
                    '${request['technicianId']['province'] ?? ''}, ${request['technicianId']['district'] ?? ''}, ${request['technicianId']['commune'] ?? ''}, ${request['technicianId']['address'] ?? ''}',
                  ),
                  _buildInfoRow('Kinh nghiệm', request['technicianId']['experience'] ?? 'Không có'),
                  _buildInfoRow('Mô tả kinh nghiệm', request['technicianId']['experienceDescription'] ?? 'Không có'),
                  _buildInfoRow('Tiểu sử', request['technicianId']['bio'] ?? 'Không có'),
                  _buildInfoRow('Trạng thái', request['status'] == 'approved' ? 'Đã phê duyệt' : 'Chưa phê duyệt'),
                  _buildInfoRow('Ngày gửi', request['submittedAt'] ?? 'Không có'),
                  const SizedBox(height: 24),
                  Text(
                    'Hình ảnh',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B5E3C),
                    ),
                  ),
                  const SizedBox(height: 12),
                  (request['technicianId']['images'] as List<dynamic>?)?.isNotEmpty ?? false
                      ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: (request['technicianId']['images'] as List<dynamic>?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final image = request['technicianId']['images'][index];
                      final imageUrl = FormatHelper.formatImageUrl(image['url']);
                      return GestureDetector(
                        onTap: () => _showFullScreenImages(context, request['technicianId']['images'], index),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFD4A373),
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
                    style: GoogleFonts.lora(
                      color: const Color(0xFF8B5E3C),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: request['status'] == 'approved'
                          ? null
                          : () => _approveRequest(request['_id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A373),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        elevation: 5,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Text(
                        request['status'] == 'approved' ? 'Đã phê duyệt' : 'Phê duyệt',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
              style: GoogleFonts.lora(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B5E3C),
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lora(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: const Color(0xFFD4A373),
        ),
      )
          : approvalRequests.isEmpty
          ? Center(
        child: Text(
          'Không tìm thấy yêu cầu phê duyệt',
          style: GoogleFonts.lora(
            fontSize: 18,
            color: const Color(0xFF8B5E3C),
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: approvalRequests.length,
        itemBuilder: (context, index) {
          final request = approvalRequests[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundImage: CachedNetworkImageProvider(
                  FormatHelper.formatImageUrl(request['technicianId']['avatar']['url'] ?? ''),
                ),
                backgroundColor: Colors.grey[200],
                child: request['technicianId']['avatar']['url'] == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              title: Text(
                request['technicianId']['fullName'] ?? 'Yêu cầu ${index + 1}',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: const Color(0xFF8B5E3C),
                ),
              ),
              subtitle: Text(
                request['status'] == 'approved' ? 'Đã phê duyệt' : 'Chưa phê duyệt',
                style: GoogleFonts.lora(
                  color: const Color(0xFF8B5E3C).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              onTap: () => _showRequestDetails(context, request),
              trailing: ElevatedButton(
                onPressed: request['status'] == 'approved'
                    ? null
                    : () => _approveRequest(request['_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A373),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                ),
                child: Text(
                  request['status'] == 'approved' ? 'Đã phê duyệt' : 'Phê duyệt',
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

