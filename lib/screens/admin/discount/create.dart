import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:spa_app/config/color_config.dart';

import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/discount_service.dart';
import 'package:spa_app/utils/file_util.dart';

import '../../../helper/snackbar_helper.dart';
import '../../../helper/format_helper.dart';

class CreateDiscountScreen extends StatefulWidget {
  const CreateDiscountScreen({super.key});

  @override
  State<CreateDiscountScreen> createState() => _CreateDiscountScreenState();
}

class _CreateDiscountScreenState extends State<CreateDiscountScreen> {
  final DiscountService discountService = DiscountService();
  final UploadService _uploadService = UploadService();
  final FileUtils _fileUtils = FileUtils();
  final FileService fileService = FileService();

  // Form controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _minOrderValueController = TextEditingController();
  final TextEditingController _maxUsesController = TextEditingController();

  // Form state
  String? _selectedTypeDiscount = 'fixed';
  String? _uploadedImageDiscountId;
  
  DateTime? _startDate;
  DateTime? _expiresAt;
  bool _isActive = false;
  bool _isViewHome = false;
  bool _isLoading = false;

  Map<String, dynamic>? discountImage;

  // Form validation
  final _formKey = GlobalKey<FormState>();

  // Design tokens - chuyển sang màu đỏ
  static const _primary = Color(0xFFDC2626); // Red-600
  static const _surface = Color(0xFFF8FAFC);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF0F172A);
  static const _textSecondary = Color(0xFF64748B);
  // Bổ sung các hằng số màu bị thiếu
  static const _success = Color(0xFF10B981);   // green-500
  static const _successLight = Color(0xFFD1FAE5);
  static const _error = Color(0xFFEF4444);      // red-500

  List<TextInputFormatter> _valueFormatters = [];

  @override
  void initState() {
    super.initState();
    // Giá trị mặc định cho ngày bắt đầu và kết thúc
    _startDate = DateTime.now();
    _expiresAt = DateTime.now().add(const Duration(days: 30));
    // Giá trị mặc định cho đơn hàng tối thiểu và số lượt sử dụng là 0
    _minOrderValueController.text = '0';
    _maxUsesController.text = '0';
    // Cập nhật input formatter cho trường giá trị dựa trên loại giảm giá
    _updateValueInputFormatter();
  }

  // Cập nhật input formatter để giới hạn phần trăm từ 0-100
  void _updateValueInputFormatter() {
    if (_selectedTypeDiscount == 'percentage') {
      _valueFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        _PercentageRangeFormatter(),
      ];
    } else {
      _valueFormatters = [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }

    setState(() {}); // refresh UI
  }

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minOrderValueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  Future<void> _createDiscount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra ảnh khi bật hiển thị Home
    if (_isViewHome && discountImage == null) {
      SnackBarHelper.showError(context, 'Vui lòng tải lên ảnh trước khi bật "Hiển thị trên màn hình Home".');
      return;
    }

    if (_startDate == null) {
      SnackBarHelper.showError(context, 'Vui lòng chọn ngày bắt đầu');
      return;
    }

    if (_expiresAt == null) {
      SnackBarHelper.showError(context, 'Vui lòng chọn ngày kết thúc');
      return;
    }

    if (_expiresAt!.isBefore(_startDate!)) {
      SnackBarHelper.showError(context, 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final discountData = {
        'code': _codeController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'typeDiscount': _selectedTypeDiscount,
        'value': _selectedTypeDiscount == 'percentage'
            ? int.parse(_valueController.text)
            : int.parse(_valueController.text),
        'minOrderValue': int.parse(_minOrderValueController.text),
        'maxUses': int.parse(_maxUsesController.text),
        'startAt': _startDate!.toUtc().toIso8601String(),
        'expiresAt': _expiresAt!.toUtc().toIso8601String(),
        'isActive': _isActive,
        'isViewHome': _isViewHome,
        'fileImage': discountImage,
      };

      final response = await discountService.createDiscount(discountData);
      if (response['success'] == true) {
        SnackBarHelper.showSuccess(context, 'Tạo mã giảm giá thành công');
        context.pop(true);
      } else {
        throw Exception(response['message'] ?? 'Không thể tạo mã giảm giá');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _deleteImage() async {
    if (_uploadedImageDiscountId == null) return;
    // Không cho xóa ảnh nếu đang bật hiển thị Home
    if (_isViewHome) {
      SnackBarHelper.showError(context, 'Không thể xóa ảnh khi đang bật "Hiển thị trên màn hình Home". Vui lòng tắt trước.');
      return;
    }
    try {
      await fileService.deleteFileService(_uploadedImageDiscountId!);
      setState(() {
        discountImage = null;
        _uploadedImageDiscountId = null;
      });
      SnackBarHelper.showSuccess(context, 'Đã xóa ảnh');
    } catch (e) {
      SnackBarHelper.showError(context, 'Xóa ảnh thất bại: $e');
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date != null) {
      setState(() {
        _expiresAt = date;
      });
    }
  }

  Future<void> uploadImage(String filePath) async {
    try {
      final response = await _uploadService.uploadSingleFileService(filePath);
      final imageData = response['data'];

      if (imageData != null) {
        setState(() {
            if (_uploadedImageDiscountId != null) {
              fileService.deleteFileService(_uploadedImageDiscountId!);
            }
            discountImage = imageData;
            _uploadedImageDiscountId = imageData['_id'];
        });
      } else {
        SnackBarHelper.showError(context, 'Không thể tải lên hình ảnh');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi tải lên hình ảnh: $e');
    }
  }

  Future<void> _pickImage() async {

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final double ratioX = 1.0;
      final double ratioY = 1.0;
      final File? croppedImage = await _fileUtils.cropImage(
        File(pickedFile.path),
        ratioX,
        ratioY,
      );
      if (croppedImage != null) {
        await uploadImage(croppedImage.path);
      } else {
        SnackBarHelper.showWarning(context, 'Đã hủy cắt ảnh');
      }
    }
  }

  Future<void> _recropImage() async {
    // Nếu chưa có ảnh thì gọi pick mới
    if (discountImage == null) {
      await _pickImage();
      return;
    }
    // Nếu có ảnh rồi, có thể cho phép cắt lại từ file đã lưu?
    // Nhưng vì không lưu file gốc, giải pháp đơn giản: mở gallery chọn lại.
    // Hoặc nếu muốn dùng ảnh hiện tại: cần download về -> crop -> upload lại.
    // Dưới đây là cách mở gallery để chọn ảnh mới (thay thế):
    await _pickImage();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 40, color: _textSecondary),
          const SizedBox(height: 8),
          Text(
            'Nhấn để chọn ảnh',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    _pickImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text(
          'Tạo mã giảm giá',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageSection(),
              const SizedBox(height: 10),

              // Code field
              _buildTextField(
                controller: _codeController,
                label: 'Mã giảm giá *',
                hint: 'VD: SALE2026',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mã giảm giá';
                  }
                  if (value.trim().length < 3) {
                    return 'Mã giảm giá phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Description field
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả *',
                hint: 'Mô tả về chương trình giảm giá',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Discount type
              _buildSectionTitle('Loại giảm giá *'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cố định (VNĐ)', style: TextStyle(fontSize: 14),),
                        value: 'fixed',
                        groupValue: _selectedTypeDiscount,
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeDiscount = value;
                            _valueController.clear();
                            _updateValueInputFormatter();
                          });
                        },
                        activeColor: _primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 1),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Phần trăm (%)', style: TextStyle(fontSize: 14),),
                        value: 'percentage',
                        groupValue: _selectedTypeDiscount,
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeDiscount = value;
                            _valueController.clear();
                            _updateValueInputFormatter();
                          });
                        },
                        activeColor: _primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Value field
              _buildTextField(
                controller: _valueController,
                label: _selectedTypeDiscount == 'percentage' ? 'Giá trị giảm (%) *' : 'Giá trị giảm (VNĐ) *',
                hint: _selectedTypeDiscount == 'percentage' ? 'VD: 50 (tối đa 100)' : 'VD: 50000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá trị giảm';
                  }
                  final val = int.tryParse(value);
                  if (val == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  if (_selectedTypeDiscount == 'percentage') {
                    if (val < 0 || val > 100) {
                      return 'Phần trăm giảm phải từ 0 đến 100';
                    }
                  } else {
                    if (val <= 0) {
                      return 'Giá trị giảm phải lớn hơn 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Min order value
              _buildTextField(
                controller: _minOrderValueController,
                label: 'Giá trị đơn hàng tối thiểu *',
                hint: 'VD: 400000 (0 = không yêu cầu tối thiểu)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá trị đơn hàng tối thiểu';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val < 0) {
                    return 'Vui lòng nhập số hợp lệ (>= 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max uses
              _buildTextField(
                controller: _maxUsesController,
                label: 'Số lượt sử dụng tối đa *',
                hint: 'VD: 100 (0 = không giới hạn)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số lượt sử dụng tối đa';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val < 0) {
                    return 'Vui lòng nhập số hợp lệ (>= 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start date
              _buildDatePicker(
                label: 'Ngày bắt đầu *',
                selectedDate: _startDate,
                onTap: _selectStartDate,
                hint: 'Chọn ngày bắt đầu',
              ),
              const SizedBox(height: 16),

              // Expiry date
              _buildDatePicker(
                label: 'Ngày kết thúc *',
                selectedDate: _expiresAt,
                onTap: _selectExpiryDate,
                hint: 'Chọn ngày kết thúc',
              ),
              const SizedBox(height: 16),

              // Active status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hiển thị trên màn hình Home',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'Mã giảm giá này sẽ hiển thị trên \nmàn hình Home phía khách',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isViewHome,
                      onChanged: (value) {
                        if (value == true && discountImage == null) {
                          SnackBarHelper.showError(context, 'Vui lòng tải lên ảnh trước khi bật "Hiển thị trên màn hình Home".');
                          return;
                        }
                        setState(() {
                          _isViewHome = value;
                        });
                      },
                      activeColor: _primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Active status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kích hoạt ngay',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          'Mã giảm giá sẽ có hiệu lực ngay sau khi tạo',
                          style: TextStyle(
                            fontSize: 12,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: _primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Tạo mã giảm giá',
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
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        // TEXT
        if (discountImage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: _successLight,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: _success,
                ),
                SizedBox(width: 8),
                Text(
                  'Đã tải lên ảnh thành công',
                  style: TextStyle(
                    fontSize: 13,
                    color: _success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
        ],

        // IMAGE
        Center(
          child: GestureDetector(
            onTap: _showImagePickerDialog,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 170,
              width: 170,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: discountImage != null ? _primary : _border,
                  width: discountImage != null ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: discountImage != null &&
                    discountImage!['url'] != null
                    ? Image.network(
                  FormatHelper.formatNetworkImageUrl(
                    discountImage!['url'],
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholder(),
                )
                    : _buildPlaceholder(),
              ),
            ),
          ),
        ),

        // BUTTONS
        if (discountImage != null) ...[
          const SizedBox(height: 20),

          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                // XÓA
                Container(
                  decoration: BoxDecoration(
                    color: _error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: _deleteImage,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                    ),
                    label: const Text('Xóa ảnh'),
                    style: TextButton.styleFrom(
                      foregroundColor: _error,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                // CẮT LẠI
                Container(
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: _recropImage,
                    icon: const Icon(
                      Icons.crop_rounded,
                      size: 16,
                    ),
                    label: const Text('Cắt lại'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                // THAY ẢNH
                Container(
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: _showImagePickerDialog,
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 16,
                    ),
                    label: const Text('Thay ảnh'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primary,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: _textPrimary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? FormatHelper.formatDateTimeTypeDateTime(selectedDate)
                      : hint,
                  style: TextStyle(
                    color: selectedDate != null ? _textPrimary : _textSecondary,
                  ),
                ),
                Icon(Icons.calendar_today, color: _textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: _textPrimary,
        fontSize: 14,
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Kiểm tra nếu có ảnh đã upload (và chưa tạo discount thành công)
    if (discountImage != null && !_isLoading) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận thoát'),
          content: const Text('Bạn đã tải lên ảnh mới nhưng chưa tạo mã giảm giá. Bạn có muốn thoát không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ở lại', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Thoát'),
            ),
          ],
        ),
      );
      if (shouldExit == true) {
        if (_uploadedImageDiscountId != null) {
          await fileService.deleteFileService(_uploadedImageDiscountId!);
        }
        return true;
      }
      return false;
    }
    return true;
  }
}

// Custom input formatter để giới hạn phần trăm từ 0-100
class _PercentageRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final int? value = int.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value > 100) {
      // Nếu vượt quá 100, giữ lại giá trị cũ
      return oldValue;
    }
    return newValue;
  }
}