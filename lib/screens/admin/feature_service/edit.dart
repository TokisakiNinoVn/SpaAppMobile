import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils-ok.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/information_service.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/utils/file_util.dart';
import 'dart:io';

class EditFeatureService extends StatefulWidget {
  final Map<String, dynamic> featureData;

  const EditFeatureService({
    super.key,
    required this.featureData,
  });

  @override
  State<EditFeatureService> createState() => _EditFeatureServiceState();
}

class _EditFeatureServiceState extends State<EditFeatureService> {
  final InformationService _informationService = InformationService();
  final UploadService _uploadService = UploadService();
  final FileService _fileService = FileService();
  final FileUtils _fileUtils = FileUtils(); // THÊM DÒNG NÀY

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagController;
  late TextEditingController _startPriceController;

  Map<String, dynamic>? _currentImage;
  File? _newImageFile;
  bool _isLoading = false;
  bool _isImageDeleted = false;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final data = widget.featureData;
    _titleController = TextEditingController(text: data['title'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    _tagController = TextEditingController(text: data['tag'] ?? '');
    _startPriceController = TextEditingController(text: data['startPrice'].toString() ?? "");
    _currentImage = data['fileId'] != null ? Map<String, dynamic>.from(data['fileId']) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _startPriceController.dispose();
    super.dispose();
  }

  // PHƯƠNG THỨC NÀY ĐÃ ĐƯỢC CẬP NHẬT - THÊM BƯỚC CẮT ẢNH
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Hiển thị dialog loading trong khi cắt ảnh
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Cắt ảnh với tỷ lệ phù hợp (ví dụ: 4:3 hoặc 16:9 tùy theo design)
        final File? croppedImage = await _fileUtils.cropImage(
          File(pickedFile.path),
          16,
          9,
        );

        // Đóng dialog loading
        if (context.mounted) Navigator.pop(context);

        if (croppedImage != null) {
          final oldImageId = _currentImage?['_id'];

          setState(() {
            _newImageFile = croppedImage;
            _isImageDeleted = false;
            _imageError = null;
          });

          // Xóa ảnh cũ trên server nếu có
          if (oldImageId != null) {
            try {
              var response = await _fileService.deleteFileService(oldImageId);
              appLog('Đã xóa ảnh cũ khi đổi ảnh: $oldImageId - $response');
            } catch (e) {
              appLog('Lỗi xóa ảnh cũ khi đổi: $e');
            }
          }
        } else {
          // Người dùng hủy cắt ảnh
          if (context.mounted) {
            SnackBarHelper.showWarning(context, 'Đã hủy chọn ảnh');
          }
        }
      } catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          SnackBarHelper.showError(context, 'Lỗi khi xử lý ảnh: $e');
        }
      }
    }
  }

  // PHƯƠNG THỨC MỚI - CHO PHÉP CẮT LẠI ẢNH ĐÃ CHỌN
  Future<void> _recropImage() async {
    if (_newImageFile == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final File? croppedImage = await _fileUtils.cropImage(
        _newImageFile!,
        16,
        9,
      );

      if (context.mounted) Navigator.pop(context);

      if (croppedImage != null) {
        setState(() {
          _newImageFile = croppedImage;
        });
        if (context.mounted) {
          SnackBarHelper.showSuccess(context, 'Đã cắt lại ảnh thành công');
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Lỗi khi cắt lại ảnh: $e');
      }
    }
  }

  Future<void> _deleteImage() async {
    final oldImageId = _currentImage?['_id'];

    setState(() {
      _currentImage = null;
      _newImageFile = null;
      _isImageDeleted = true;
      _imageError = 'Vui lòng tải lên ảnh mới';
    });

    if (oldImageId != null) {
      try {
        var response = await _fileService.deleteFileService(oldImageId);
        appLog('Đã xóa ảnh cũ thành công: $oldImageId - $response');
      } catch (e) {
        appLog('Lỗi xóa ảnh cũ: $e');
      }
    }
  }

  Future<dynamic> _uploadNewImage() async {
    if (_newImageFile == null) return null;

    try {
      final response = await _uploadService.uploadSingleFileService(_newImageFile!.path);
      appLog("upload image: $response");
      final imageData = response['data'];

      if (imageData != null) {
        return imageData;
      } else {
        throw Exception('Không thể tải lên hình ảnh');
      }
    } catch (e) {
      throw Exception('Lỗi tải lên hình ảnh: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_titleController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập tiêu đề');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập mô tả');
      return;
    }

    if (_currentImage == null && _newImageFile == null) {
      SnackBarHelper.showError(context, 'Vui lòng tải lên ảnh cho dịch vụ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? newImageData;

      if (_newImageFile != null) {
        newImageData = await _uploadNewImage();
        if (newImageData == null) {
          throw Exception('Không thể tải lên ảnh mới');
        }
      }

      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'tag': _tagController.text.trim(),
        'startPrice': _startPriceController.text.trim(),
      };

      if (newImageData != null && newImageData['_id'] != null) {
        updateData['fileId'] = newImageData['_id'];
      }
      else if (_currentImage != null && !_isImageDeleted && _newImageFile == null) {
        updateData['fileId'] = _currentImage!['_id'];
      }

      final featureId = widget.featureData['_id'];
      final response = await _informationService.updateFeatureService(featureId, updateData);

      if (response['status'] == 'success') {
        SnackBarHelper.showSuccess(context, 'Cập nhật thành công');
        Navigator.pop(context, true);
      } else {
        throw Exception(response['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi cập nhật: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Chỉnh sửa",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                _buildImageSection(),

                const SizedBox(height: 28),

                // Title Section
                _buildTextField(
                  controller: _titleController,
                  label: 'Tiêu đề',
                  hint: 'Nhập tiêu đề dịch vụ',
                  icon: Icons.title,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // Description Section
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Mô tả',
                  hint: 'Nhập mô tả chi tiết về dịch vụ',
                  icon: Icons.description,
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                // Tag Section
                _buildTextField(
                  controller: _tagController,
                  label: 'Tag',
                  hint: 'Ví dụ: Phổ biến, Mới, Đặc biệt...',
                  icon: Icons.local_offer,
                  maxLines: 1,
                ),
                
                // Giá thấp nhất từ
                _buildTextField(
                  controller: _startPriceController,
                  label: 'Giá thấp nhất từ',
                  hint: '250.000',
                  icon: Icons.local_offer,
                  maxLines: 1,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConfig.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5E9B8C),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 22,
                color: ColorConfig.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hình ảnh dịch vụ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_imageError != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Bắt buộc',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Image display
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _imageError != null ? Colors.red.shade300 : Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: _currentImage != null || _newImageFile != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _newImageFile != null
                      ? Image.file(
                    _newImageFile!,
                    fit: BoxFit.cover,
                  )
                      : _currentImage != null && _currentImage!['url'] != null
                      ? Image.network(
                    FormatHelper.formatNetworkImageUrl(_currentImage!['url']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF5E9B8C),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  )
                      : _buildImagePlaceholder(),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (_newImageFile != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _recropImage,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.crop,
                                  color: ColorConfig.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _deleteImage,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                : _buildImagePlaceholderWithButton(),
          ),
        ),

        const SizedBox(height: 16),

        // Upload button
        Center(
          child: (_currentImage == null && _newImageFile == null || _isImageDeleted)
              ? ElevatedButton.icon(
            onPressed: _pickImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConfig.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: const Text(
              'Chọn ảnh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // THÊM NÚT CẮT LẠI ẢNH Ở DƯỚI
              if (_newImageFile != null)
                OutlinedButton.icon(
                  onPressed: _recropImage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorConfig.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(color: ColorConfig.primary),
                  ),
                  icon: const Icon(Icons.crop, size: 18),
                  label: const Text(
                    'Cắt lại',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConfig.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: ColorConfig.primary),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text(
                  'Đổi ảnh',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_imageError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade600),
                  const SizedBox(width: 6),
                  Text(
                    _imageError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Không thể tải ảnh',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholderWithButton() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Chọn ảnh',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bắt buộc phải có ảnh',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: ColorConfig.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5E9B8C), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}