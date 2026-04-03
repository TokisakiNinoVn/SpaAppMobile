import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spa_app/services/file_service.dart';
import 'package:spa_app/services/upload_service.dart';
import 'package:spa_app/services/discount_service.dart';

import '../../../helper/snackbar_helper.dart';
import '../../../services/discount_service.dart';
import 'package:spa_app/helper/format_helper.dart';

class EditDiscountScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const EditDiscountScreen({super.key, this.data});

  @override
  State<EditDiscountScreen> createState() => _EditDiscountScreenState();
}

class _EditDiscountScreenState extends State<EditDiscountScreen> {
  final DiscountService discountService = DiscountService();

  // Form controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _minOrderValueController = TextEditingController();
  final TextEditingController _maxUsesController = TextEditingController();

  // Form state
  String? _selectedTypeDiscount = 'fixed';
  DateTime? _startDate;
  DateTime? _expiresAt;
  bool _isActive = false;
  bool _isLoading = false;
  int _usedCount = 0;
  String? _discountId;

  // Form validation
  final _formKey = GlobalKey<FormState>();

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

  @override
  void initState() {
    super.initState();
    _loadDiscountData();
  }

  void _loadDiscountData() {
    if (widget.data != null) {
      print("Data discount Edit: ${widget.data}");

      // Store discount ID and used count
      _discountId = widget.data!['_id'];
      _usedCount = widget.data!['usedCount'] ?? 0;

      // Load data into controllers
      _codeController.text = widget.data!['code'] ?? '';
      _descriptionController.text = widget.data!['description'] ?? '';
      _selectedTypeDiscount = widget.data!['typeDiscount'] ?? 'fixed';
      _valueController.text = widget.data!['value'].toString();
      _minOrderValueController.text = widget.data!['minOrderValue'].toString();
      _maxUsesController.text = widget.data!['maxUses'].toString();
      _startDate = widget.data!['startAt'] != null
          ? DateTime.parse(widget.data!['startAt'])
          : null;
      _expiresAt = widget.data!['expiresAt'] != null
          ? DateTime.parse(widget.data!['expiresAt'])
          : null;
      _isActive = widget.data!['isActive'] ?? false;
    }
  }

  bool get _isEditable => _usedCount == 0;

  Future<void> _updateDiscount() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates
    if (_startDate == null) {
      SnackbarHelper.showError(context, 'Vui lòng chọn ngày bắt đầu');
      return;
    }

    if (_expiresAt == null) {
      SnackbarHelper.showError(context, 'Vui lòng chọn ngày kết thúc');
      return;
    }

    if (_expiresAt!.isBefore(_startDate!)) {
      SnackbarHelper.showError(context, 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final discountData = <String, dynamic>{};

      // Always editable fields
      discountData['description'] = _descriptionController.text.trim();
      discountData['startAt'] = _startDate!.toUtc().toIso8601String();
      discountData['expiresAt'] = _expiresAt!.toUtc().toIso8601String();
      discountData['maxUses'] = int.parse(_maxUsesController.text);

      // Only include these fields if discount hasn't been used
      if (_isEditable) {
        discountData['code'] = _codeController.text.trim().toUpperCase();
        discountData['typeDiscount'] = _selectedTypeDiscount;
        discountData['value'] = _selectedTypeDiscount == 'percentage'
            ? int.parse(_valueController.text)
            : int.parse(_valueController.text);
        discountData['minOrderValue'] = int.parse(_minOrderValueController.text);
        discountData['isActive'] = _isActive;
      } else {
        discountData['isActive'] = _isActive;
      }
      var response;
      if (!_isEditable) {
        response = await discountService.updateIsUseDiscount(_discountId!, discountData);
      } else {
        response = await discountService.updateDiscount(_discountId!, discountData);
      }

      if (response['success'] == true) {
        SnackbarHelper.showSuccess(context, 'Cập nhật mã giảm giá thành công');
        context.pop(true);
      } else {
        throw Exception(response['message'] ?? 'Không thể cập nhật mã giảm giá');
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Lỗi: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: Text(
          _isEditable ? 'Chỉnh sửa mã giảm giá' : 'Xem chi tiết mã giảm giá',
          style: const TextStyle(fontWeight: FontWeight.w600),
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
              // Show warning if discount has been used
              if (!_isEditable)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mã giảm giá này đã được sử dụng $_usedCount lần. Chỉ có thể chỉnh sửa mô tả, ngày hiệu lực, số lượt sử dụng tối đa và trạng thái.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Code field
              _buildTextField(
                controller: _codeController,
                label: 'Mã giảm giá *',
                hint: 'VD: SALE2026',
                enabled: _isEditable,
                validator: (value) {
                  if (!_isEditable) return null;
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

              // Description field (always editable)
              _buildTextField(
                controller: _descriptionController,
                label: 'Mô tả *',
                hint: 'Mô tả về chương trình giảm giá',
                maxLines: 3,
                enabled: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Discount type - only editable if not used
              _buildSectionTitle('Loại giảm giá *'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _isEditable ? Colors.white : _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cố định (VNĐ)'),
                        value: 'fixed',
                        groupValue: _selectedTypeDiscount,
                        onChanged: _isEditable ? (value) {
                          setState(() {
                            _selectedTypeDiscount = value;
                            _valueController.clear();
                          });
                        } : null,
                        activeColor: _primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Phần trăm (%)'),
                        value: 'percentage',
                        groupValue: _selectedTypeDiscount,
                        onChanged: _isEditable ? (value) {
                          setState(() {
                            _selectedTypeDiscount = value;
                            _valueController.clear();
                          });
                        } : null,
                        activeColor: _primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Value field - only editable if not used
              _buildTextField(
                controller: _valueController,
                label: _selectedTypeDiscount == 'percentage' ? 'Giá trị giảm (%) *' : 'Giá trị giảm (VNĐ) *',
                hint: _selectedTypeDiscount == 'percentage' ? 'VD: 50' : 'VD: 50000',
                keyboardType: TextInputType.number,
                enabled: _isEditable,
                validator: (value) {
                  if (!_isEditable) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá trị giảm';
                  }
                  final val = int.tryParse(value);
                  if (val == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  if (_selectedTypeDiscount == 'percentage') {
                    if (val < 0 || val > 100) {
                      return 'Phần trăm giảm phải từ 0-100';
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

              // Min order value - only editable if not used
              _buildTextField(
                controller: _minOrderValueController,
                label: 'Giá trị đơn hàng tối thiểu *',
                hint: 'VD: 400000',
                keyboardType: TextInputType.number,
                enabled: _isEditable,
                validator: (value) {
                  if (!_isEditable) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập giá trị đơn hàng tối thiểu';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val < 0) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Max uses (always editable)
              _buildTextField(
                controller: _maxUsesController,
                label: 'Số lượt sử dụng tối đa *',
                hint: 'VD: 100',
                keyboardType: TextInputType.number,
                enabled: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số lượt sử dụng tối đa';
                  }
                  final val = int.tryParse(value);
                  if (val == null || val <= 0) {
                    return 'Số lượt sử dụng phải lớn hơn 0';
                  }
                  if (val < _usedCount) {
                    return 'Số lượt sử dụng tối đa không thể nhỏ hơn số lượt đã dùng ($_usedCount)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start date (always editable)
              _buildDatePicker(
                label: 'Ngày bắt đầu *',
                selectedDate: _startDate,
                onTap: _selectStartDate,
                hint: 'Chọn ngày bắt đầu',
                enabled: true,
              ),
              const SizedBox(height: 16),

              // Expiry date (always editable)
              _buildDatePicker(
                label: 'Ngày kết thúc *',
                selectedDate: _expiresAt,
                onTap: _selectExpiryDate,
                hint: 'Chọn ngày kết thúc',
                enabled: true,
              ),
              const SizedBox(height: 16),

              // Active status (always editable)
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
                          'Kích hoạt',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          _isEditable
                              ? 'Bật/tắt trạng thái hoạt động của mã giảm giá'
                              : 'Trạng thái hoạt động của mã giảm giá',
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

              // Update button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      : Text(
                    _isEditable ? 'Cập nhật mã giảm giá' : 'Lưu thay đổi',
                    style: const TextStyle(
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
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
            color: enabled ? _textPrimary : _textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
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
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: enabled ? _textPrimary : _textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : _surface,
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
                Icon(
                  Icons.calendar_today,
                  color: enabled ? _textSecondary : _textSecondary.withOpacity(0.5),
                  size: 20,
                ),
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

  @override
  void dispose() {
    _codeController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minOrderValueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }
}