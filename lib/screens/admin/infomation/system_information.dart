import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/information_service.dart';

enum TimeUnit { days, hours, minutes }

class ManagementSystemInformation extends StatefulWidget {
  const ManagementSystemInformation({super.key});

  @override
  State<ManagementSystemInformation> createState() => _ManagementSystemInformationState();
}

class _ManagementSystemInformationState extends State<ManagementSystemInformation> {
  final InformationService _informationService = InformationService();
  final _formKey = GlobalKey<FormState>();

  Map<String, dynamic> _systemInfo = {};

  // Controllers cho thông tin cơ bản
  late TextEditingController _nameController;
  late TextEditingController _versionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _sloganController;
  late TextEditingController _otherNameController;
  late TextEditingController _emailController;

  // Controllers cho timeout
  late TextEditingController _orderValueController;
  late TextEditingController _autoMatchingValueController;

  TimeUnit _orderUnit = TimeUnit.minutes;
  TimeUnit _autoMatchingUnit = TimeUnit.minutes;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _getSystemInfo();
  }

  void _initControllers() {
    _nameController = TextEditingController();
    _versionController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _sloganController = TextEditingController();
    _otherNameController = TextEditingController();
    _emailController = TextEditingController();

    _orderValueController = TextEditingController();
    _autoMatchingValueController = TextEditingController();
  }

  Future<void> _getSystemInfo() async {
    final result = await _informationService.getInformationSystem();
    if (result['success'] && result['data'] != null) {
      setState(() => _systemInfo = result['data']);

      // Đổ dữ liệu thông tin cơ bản
      _nameController.text = _systemInfo['name'] ?? '';
      _versionController.text = _systemInfo['version'] ?? '';
      _addressController.text = _systemInfo['address'] ?? '';
      _phoneController.text = _systemInfo['phone'] ?? '';
      _sloganController.text = _systemInfo['slogan'] ?? '';
      _otherNameController.text = _systemInfo['otherName'] ?? '';
      _emailController.text = _systemInfo['email'] ?? '';

      // Xử lý Order Timeout
      final orderMinutes = _systemInfo['orderRequestTimeoutMinutes'] ?? 5;
      final orderConverted = _minutesToValueAndUnit(orderMinutes);
      _orderValueController.text = orderConverted.value.toString();
      _orderUnit = orderConverted.unit;

      // Xử lý Auto Matching Timeout
      final autoMinutes = _systemInfo['autoMatchingRequestTimeoutMinutes'] ?? 30;
      final autoConverted = _minutesToValueAndUnit(autoMinutes);
      _autoMatchingValueController.text = autoConverted.value.toString();
      _autoMatchingUnit = autoConverted.unit;
    }
  }

  // Chuyển từ phút sang Value + Unit phù hợp nhất
  ({int value, TimeUnit unit}) _minutesToValueAndUnit(int minutes) {
    if (minutes % (24 * 60) == 0) {
      return (value: minutes ~/ (24 * 60), unit: TimeUnit.days);
    } else if (minutes % 60 == 0) {
      return (value: minutes ~/ 60, unit: TimeUnit.hours);
    } else {
      return (value: minutes, unit: TimeUnit.minutes);
    }
  }

  int _valueToMinutes(int value, TimeUnit unit) {
    switch (unit) {
      case TimeUnit.days:
        return value * 24 * 60;
      case TimeUnit.hours:
        return value * 60;
      case TimeUnit.minutes:
        return value;
    }
  }

  Future<void> _updateSystemInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final orderMinutes = _valueToMinutes(
      int.tryParse(_orderValueController.text) ?? 0,
      _orderUnit,
    );

    final autoMinutes = _valueToMinutes(
      int.tryParse(_autoMatchingValueController.text) ?? 0,
      _autoMatchingUnit,
    );


    final payload = {
      "name": _nameController.text.trim(),
      "version": _versionController.text.trim(),
      "address": _addressController.text.trim(),
      "phone": _phoneController.text.trim(),
      "slogan": _sloganController.text.trim(),
      "otherName": _otherNameController.text.trim(),
      "email": _emailController.text.trim(),
      "orderRequestTimeoutMinutes": orderMinutes,
      "autoMatchingRequestTimeoutMinutes": autoMinutes,
    };

    appLog("Data payload: $payload");

    final result = await _informationService.updateInformationSystem(payload);

    if (mounted) {
      if (result['success']) {
        SnackBarHelper.showSuccess(context, "Cập nhật thông tin hệ thống thành công!");
        context.pop();
      } else {
        SnackBarHelper.showError(context, result['message'] ?? 'Cập nhật thất bại'); // sửa Success thành Error nếu cần
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _versionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _sloganController.dispose();
    _otherNameController.dispose();
    _emailController.dispose();
    _orderValueController.dispose();
    _autoMatchingValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _systemInfo["name"] ?? "Thông tin hệ thống",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: _updateSystemInfo,
            style: TextButton.styleFrom(
              backgroundColor: ColorConfig.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // side: const BorderSide(
              //   color: Colors.blue,
              //   width: 1,
              // ),
              // elevation: 2,
            ),
            icon: const Icon(Icons.check, size: 20),
            label: const Text(
              "Lưu",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),

        ],
      ),
      body: _systemInfo.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Thông tin cơ bản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildTextField("Tên Spa", _nameController, Icons.spa, isRequired: true),
              _buildTextField("Phiên bản", _versionController, Icons.info_outline, isRequired: true),
              _buildTextField("Địa chỉ", _addressController, Icons.location_on_outlined, isRequired: true, maxLines: 2),
              _buildTextField("Số điện thoại", _phoneController, Icons.phone_outlined, isRequired: true, keyboardType: TextInputType.phone),
              _buildTextField("Slogan", _sloganController, Icons.campaign_outlined, isRequired: true, maxLines: 2),
              _buildTextField("Tên khác", _otherNameController, Icons.badge_outlined, isRequired: true),
              _buildTextField("Email", _emailController, Icons.email_outlined, isRequired: true, keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 32),
              const Text("Thời gian timeout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              _buildTimeoutField(
                label: "Yêu cầu đơn đặt (ngay & trước)",
                valueController: _orderValueController,
                unit: _orderUnit,
                onUnitChanged: (unit) => setState(() => _orderUnit = unit),
                minValue: 1,
              ),
              _buildTimeoutField(
                label: "Yêu cầu ghép KTV tự động",
                valueController: _autoMatchingValueController,
                unit: _autoMatchingUnit,
                onUnitChanged: (unit) => setState(() => _autoMatchingUnit = unit),
                minValue: 1,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Field cho timeout mới
  Widget _buildTimeoutField({
    required String label,
    required TextEditingController valueController,
    required TimeUnit unit,
    required Function(TimeUnit) onUnitChanged,
    required int minValue,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: valueController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "Giá trị",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    final num = int.tryParse(value ?? '');
                    if (num == null || num < minValue) {
                      return 'Tối thiểu $minValue';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<TimeUnit>(
                  value: unit,
                  decoration: InputDecoration(
                    labelText: "Đơn vị",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: TimeUnit.days, child: Text("Ngày")),
                    DropdownMenuItem(value: TimeUnit.hours, child: Text("Giờ")),
                    DropdownMenuItem(value: TimeUnit.minutes, child: Text("Phút")),
                  ],
                  onChanged: (newUnit) {
                    if (newUnit != null) onUnitChanged(newUnit);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Giữ lại _buildTextField cũ (không thay đổi)
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        bool isRequired = false,
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConfig.primary, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Không được để trống';
          }
          if (label.contains("điện thoại") && value != null && value.isNotEmpty) {
            if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
              return 'Số điện thoại phải bắt đầu bằng 0 và có 10 số';
            }
          }
          return null;
        },
      ),
    );
  }
}