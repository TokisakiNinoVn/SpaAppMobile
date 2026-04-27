import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/withdraw_service.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/upload_service.dart';

class ConfirmRequestScreen extends StatefulWidget {
  final String id;
  final String type; // 'reject' hoặc 'accept'
  final Map<String, dynamic>? withdrawDetail;

  const ConfirmRequestScreen({
    super.key,
    required this.id,
    required this.type,
    this.withdrawDetail,
  });

  @override
  State<ConfirmRequestScreen> createState() => _ConfirmRequestScreenState();
}

class _ConfirmRequestScreenState extends State<ConfirmRequestScreen> {
  final WithdrawService _withdrawService = WithdrawService();
  final FileService _fileService = FileService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String _note = '';
  String _reasonRefusal = '';
  List<UploadedImage> _uploadedImages = [];

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _reasonRefusalController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _reasonRefusalController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    await _uploadImage(pickedFile.path);
  }

  Future<void> _uploadImage(String filePath) async {
    setState(() => _isLoading = true);

    try {
      final response = await _uploadService.uploadSingleFileService(filePath);
      final imageData = response['data'];
      appLog("${response['data']['_id']} - ${response['data']['url']}");

      if (imageData != null) {
        setState(() {
          _uploadedImages.add(UploadedImage(
            id: imageData['_id'] ?? imageData['id'],
            url: imageData['url'] ?? "",
            localPath: filePath,
          ));
        });
        SnackBarHelper.showSuccess(context, 'Tải ảnh lên thành công');
      } else {
        SnackBarHelper.showError(context, 'Không thể tải lên hình ảnh');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải lên hình ảnh: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUploadedImage(int index) async {
    final image = _uploadedImages[index];

    try {
      if (image.id.isNotEmpty) {
        var response = await _fileService.deleteFileService(image.id);
        appLog("${response}");
        setState(() {
          _uploadedImages.removeAt(index);
        });
        SnackBarHelper.showSuccess(context, 'Đã xóa ảnh');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi khi xóa ảnh: $e');
    }
  }

  Future<void> _deleteAllUploadedImages() async {
    if (_uploadedImages.isEmpty) return;

    try {
      for (var image in _uploadedImages) {
        await _fileService.deleteFileService(image.id);
      }
      setState(() {
        _uploadedImages.clear();
      });
      SnackBarHelper.showSuccess(context, 'Đã xóa tất cả ảnh');
    } catch (e) {
      print('Lỗi khi xóa ảnh: $e');
    }
  }

  void _showExitConfirmation() {
    if (_uploadedImages.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Xác nhận thoát'),
            content: const Text(
              'Bạn có ảnh đã upload chưa được lưu. Bạn có muốn thoát không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Ở lại'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteAllUploadedImages();
                  if (mounted) context.pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Thoát'),
              ),
            ],
          );
        },
      );
    } else {
      context.pop();
    }
  }

  Future<void> _submitConfirm() async {
    if (widget.type == 'accept' && _uploadedImages.isEmpty) {
      SnackBarHelper.showWarning(context, 'Vui lòng chọn ảnh bill thanh toán');
      return;
    }

    if (widget.type == 'reject' && _reasonRefusal.isEmpty) {
      SnackBarHelper.showWarning(context, 'Vui lòng nhập lý do từ chối');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              widget.type == 'accept' ? 'Xác nhận thanh toán' : 'Xác nhận từ chối'
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.type == 'accept'
                    ? 'Bạn có chắc chắn đã thanh toán số tiền này cho khách hàng?'
                    : 'Bạn có chắc chắn muốn từ chối yêu cầu rút tiền này?',
              ),
              if (widget.type == 'accept' && _uploadedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Đã upload ${_uploadedImages.length} ảnh bill',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.type == 'accept' ? _confirmWithdraw() : _rejectWithdraw();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.type == 'accept' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(widget.type == 'accept' ? 'Xác nhận' : 'Từ chối'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmWithdraw() async {
    setState(() => _isLoading = true);

    try {
      final data = {
        "id": widget.id,
        'status': 'completed',
        'note': _note,
        "billFileIds": _uploadedImages.map((e) => e.id).toList(),
      };

      final response = await _withdrawService.confirmRequestWithdraw(data);
      appLog("response: ${response}");

      if (response['status'] == 'success') {
        SnackBarHelper.showSuccess(context, 'Xác nhận thanh toán thành công');
        context.go(AdminRouterConfig.listWithdraw);
      } else {
        throw Exception(response['message'] ?? 'Xác nhận thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectWithdraw() async {
    setState(() => _isLoading = true);

    try {
      final data = {
        "id": widget.id,
        'status': 'failed',
        'reasonRefusal': _reasonRefusal,
        'note': _note,
      };

      final response = await _withdrawService.confirmRequestWithdraw(data);

      if (response['status'] == 'success') {
        SnackBarHelper.showSuccess(context, 'Đã từ chối yêu cầu');
        context.go(AdminRouterConfig.listWithdraw);
      } else {
        throw Exception(response['message'] ?? 'Từ chối thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                onPressed: _showExitConfirmation,
              ),
              const SizedBox(width: 8),
              Text(
                widget.type == 'accept' ? 'Xác nhận thanh toán' : 'Xác nhận từ chối',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.withdrawDetail != null) ...[
                    _buildWithdrawInfo(),
                    const SizedBox(height: 24),
                  ],
                  if (widget.type == 'accept') ...[
                    _buildBillUploadSection(),
                    const SizedBox(height: 24),
                  ],
                  if (widget.type == 'reject') ...[
                    _buildRejectReasonSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildNoteSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildSubmitButton(),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawInfo() {
    final detail = widget.withdrawDetail!;
    final bankInfo = detail['bankInfor'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin yêu cầu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        _buildSimpleInfoRow('Mã giao dịch', detail['code'] ?? 'N/A'),
        const SizedBox(height: 10),
        _buildSimpleInfoRow('Số tiền', FormatHelper.formatPrice(detail['amount'] ?? 0)),
        const SizedBox(height: 10),
        _buildSimpleInfoRow('Phí', FormatHelper.formatPrice(detail['fee'] ?? 0)),
        const SizedBox(height: 10),
        _buildSimpleInfoRow('Thực nhận', FormatHelper.formatPrice(detail['netAmount'] ?? 0),
            isBold: true, valueColor: Colors.green),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
        const SizedBox(height: 16),
        const Text(
          'Thông tin ngân hàng',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        _buildSimpleInfoRow('Ngân hàng', bankInfo?['bankName'] ?? 'N/A'),
        const SizedBox(height: 10),
        _buildSimpleInfoRow('Số tài khoản', bankInfo?['accountNumber'] ?? 'N/A'),
        const SizedBox(height: 10),
        _buildSimpleInfoRow('Chủ tài khoản', bankInfo?['accountHolder'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildSimpleInfoRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBillUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ảnh bill thanh toán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(width: 4),
            Text('*', style: TextStyle(color: Colors.red[600], fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),

        // Danh sách ảnh đã upload
        if (_uploadedImages.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          FormatHelper.formatNetworkImageUrl(_uploadedImages[index].url),
                          width: 100,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 120,
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(Icons.broken_image, color: Color(0xFFC7C7CC)),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _deleteUploadedImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Nút thêm ảnh
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, color: Colors.grey[500], size: 20),
                const SizedBox(width: 8),
                Text(
                  _uploadedImages.isEmpty ? 'Thêm ảnh bill' : 'Thêm ảnh khác',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hỗ trợ định dạng: JPG, PNG. Tối đa 5MB/ảnh',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildRejectReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Lý do từ chối',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(width: 4),
            Text('*', style: TextStyle(color: Colors.red[600], fontSize: 16)),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonRefusalController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập lý do từ chối...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
          ),
          onChanged: (value) => setState(() => _reasonRefusal = value),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi chú',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú (không bắt buộc)...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFF9F9F9),
          ),
          onChanged: (value) => setState(() => _note = value),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.type == 'accept' ? ColorConfig.primary : const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            elevation: 0,
          ),
          child: Text(
            widget.type == 'accept' ? 'Xác nhận thanh toán' : 'Xác nhận từ chối',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class UploadedImage {
  final String id;
  final String url;
  final String localPath;

  UploadedImage({
    required this.id,
    required this.url,
    required this.localPath,
  });
}