import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/utils/file_util.dart';

import '../../../helper/snackbar_helper.dart';
import '../../../services/banner_service.dart';
import 'package:spa_app/helper/format_helper.dart';

class EditBannerScreen extends StatefulWidget {
  final Map<String, dynamic>? data;

  const EditBannerScreen({super.key, this.data});

  @override
  State<EditBannerScreen> createState() => _EditBannerScreenState();
}

class _EditBannerScreenState extends State<EditBannerScreen>
    with SingleTickerProviderStateMixin {
  final FileService fileService = FileService();
  final BannerService bannerService = BannerService();
  final UploadService uploadService = UploadService();
  final ImagePicker _picker = ImagePicker();
  final FileUtils _fileUtils = FileUtils();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  File? _selectedImage;
  String? _uploadedFileId;
  String? _uploadedImageUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _display = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Design tokens
  static const _primary = Color(0xFF2563EB);
  static const _primaryLight = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  static const _success = Color(0xFF16A34A);
  static const _successLight = Color(0xFFF0FDF4);
  static const _error = Color(0xFFDC2626);
  static const _errorLight = Color(0xFFFEF2F2);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    print("Data banner: ${widget.data}");
    if (widget.data != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    setState(() {
      _titleController.text = widget.data?['title'] ?? '';
      _contentController.text = widget.data?['content'] ?? '';
      _uploadedFileId = widget.data?['fileId'];
      _uploadedImageUrl = widget.data?['urlImage'];
      _display = widget.data?['display'] ?? false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // final File? croppedImage = await _fileUtils.cropImage(
        //     File(pickedFile.path),
        //     16.0,
        //     9.0
        // );

        final File? croppedImage = await _fileUtils.cropImage(
          context,
          File(pickedFile.path),
          16.0,
          9.0,
        );

        if (croppedImage != null) {
          setState(() => _selectedImage = croppedImage);
          await _uploadImage();
        } else {
          // Nếu người dùng hủy cắt, không upload ảnh
          SnackBarHelper.showWarning(context, 'Đã hủy cắt ảnh');
        }
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;
    setState(() => _isUploading = true);
    try {
      final response =
      await uploadService.uploadSingleFileService(_selectedImage!.path);
      final imageData = response['data'];
      if (imageData != null) {
        setState(() {
          _uploadedFileId = imageData['_id'];
          _uploadedImageUrl = imageData['url'];
          _isUploading = false;
        });
        SnackBarHelper.showSuccess(context, 'Tải lên hình ảnh thành công');
      } else {
        setState(() => _isUploading = false);
        SnackBarHelper.showError(context, 'Không thể tải lên hình ảnh');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      SnackBarHelper.showError(context, 'Lỗi tải lên hình ảnh: $e');
    }
  }

  Future<void> _deleteCurrentImage() async {
    if (_uploadedFileId == null) {
      SnackBarHelper.showError(context, 'Không có ảnh để xóa');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa ảnh banner'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh banner này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isLoading = true);
    try {
      final response = await fileService.deleteFileService(_uploadedFileId!);
      if (response['status'] == 'success') {
        setState(() {
          _uploadedFileId = null;
          _uploadedImageUrl = null;
          _selectedImage = null;
          _isLoading = false;
        });
        SnackBarHelper.showSuccess(context, 'Đã xóa ảnh banner');
      } else {
        setState(() => _isLoading = false);
        SnackBarHelper.showError(context, 'Không thể xóa ảnh banner');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      SnackBarHelper.showError(context, 'Lỗi xóa ảnh: $e');
    }
  }

  Future<void> _updateBanner() async {
    if (_titleController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập tiêu đề banner');
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Vui lòng nhập nội dung banner');
      return;
    }
    if (_uploadedFileId == null) {
      SnackBarHelper.showError(context, 'Vui lòng chọn hình ảnh cho banner');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bannerData = {
        'fileId': _uploadedFileId,
        'urlImage': _uploadedImageUrl,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'display': _display,
      };
      final response = await bannerService.updateBanner(widget.data?["_id"], bannerData);
      if (response['success'] == true || response['message'] != null) {
        SnackBarHelper.showSuccess(context, 'Cập nhật banner thành công');
        context.pop(true);
      } else {
        throw Exception(response['message'] ?? 'Không thể cập nhật banner');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Chọn ảnh banner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _BottomSheetOption(
                icon: Icons.camera_alt_rounded,
                label: 'Chụp ảnh mới',
                iconColor: _primary,
                iconBg: _primaryLight,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _BottomSheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Chọn từ thư viện',
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFF5F3FF),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 16),
              _buildFormSection(),
              const SizedBox(height: 16),
              _buildDisplaySection(),
              const SizedBox(height: 28),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: _textPrimary,
      ),
      title: const Text(
        'Chỉnh sửa banner',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('HÌNH ẢNH BANNER'),
        GestureDetector(
          onTap: _showImagePickerDialog,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _uploadedImageUrl != null ? _primary : _border,
                width: _uploadedImageUrl != null ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildImageContent(),
            ),
          ),
        ),
        if (_uploadedImageUrl != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: _success),
                    SizedBox(width: 5),
                    Text(
                      'Đã tải lên thành công',
                      style: TextStyle(fontSize: 12, color: _success, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // TextButton.icon(
              //   onPressed: _showImagePickerDialog,
              //   icon: const Icon(Icons.edit_rounded, size: 14),
              //   label: const Text('Thay ảnh'),
              //   style: TextButton.styleFrom(
              //     foregroundColor: _primary,
              //     textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              //   ),
              // ),
              const SizedBox(width: 4),
              // Nút xóa ảnh
              TextButton.icon(
                onPressed: _deleteCurrentImage,
                icon: const Icon(Icons.delete_outline_rounded, size: 14),
                label: const Text('Xóa ảnh'),
                style: TextButton.styleFrom(
                  foregroundColor: _error,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImageContent() {
    if (_isUploading) {
      return Container(
        color: _primaryLight,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primary, strokeWidth: 2.5),
              SizedBox(height: 14),
              Text(
                'Đang tải lên...',
                style: TextStyle(color: _primary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    if (_uploadedImageUrl != null) {
      return Image.network(
        FormatHelper.formatNetworkImageUrl(_uploadedImageUrl!),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _emptyImagePlaceholder(),
      );
    }

    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity);
    }

    return _emptyImagePlaceholder();
  }

  Widget _emptyImagePlaceholder() {
    return Container(
      color: _surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_rounded, size: 32, color: _primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'Chạm để chọn hình ảnh',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'JPG, PNG · Tối đa 5MB',
            style: TextStyle(fontSize: 12, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Tiêu đề',
            hint: 'Nhập tiêu đề banner...',
            maxLines: 2,
            maxLength: 100,
            icon: Icons.title_rounded,
            isFirst: true,
          ),
          Divider(height: 1, color: _border),
          _buildTextField(
            controller: _contentController,
            label: 'Nội dung',
            hint: 'Mô tả ngắn về banner...',
            maxLines: 4,
            maxLength: 200,
            icon: Icons.notes_rounded,
            isFirst: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    required int maxLength,
    required IconData icon,
    required bool isFirst,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: maxLines,
            maxLength: maxLength,
            style: const TextStyle(fontSize: 14, color: _textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _display ? _primaryLight : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _display ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 20,
                color: _display ? _primary : _textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hiển thị banner',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _display
                        ? 'Banner đang được hiển thị cho người dùng'
                        : 'Banner đang bị ẩn, không hiển thị với người dùng',
                    style: const TextStyle(fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Transform.scale(
              scale: 0.9,
              child: Switch.adaptive(
                value: _display,
                onChanged: (val) => setState(() => _display = val),
                activeColor: _primary,
                activeTrackColor: _primaryLight,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: const BorderSide(color: _border, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: _textSecondary,
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateBanner,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withOpacity(0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.save_rounded, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Cập nhật',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

/// Bottom sheet option tile
class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      onTap: onTap,
    );
  }
}