import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';

import '../../../helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import '../../../routes/config/customer_router_config.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final CustomerService _customerService = CustomerService();

  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _gender = 'female';
  bool _loading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
  }

  Future<void> _loadCustomerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProfile = prefs.getString('customerProfile');

      if (rawProfile != null) {
        final profile = jsonDecode(rawProfile) as Map<String, dynamic>;

        _fullnameController.text = profile['fullname'] ?? '';
        // _addressController.text = profile['address'] ?? '';
        _bioController.text = profile['bio'] ?? '';
        _gender = profile['gender'] ?? 'female';
      }
    } catch (e) {
      // LoggerUtils.error('Error loading customer profile from local', e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveProfileToLocal(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('customerProfile', jsonEncode(profile));
    } catch (e) {
      // LoggerUtils.error('Error saving profile to local storage', e);
    }
  }

  Future<void> _updateProfile() async {
    if (_isUpdating) return;

    final payload = {
      "fullname": _fullnameController.text.trim(),
      "gender": _gender,
      // "address": _addressController.text.trim(),
      "bio": _bioController.text.trim(),
    };

    setState(() => _isUpdating = true);

    try {
      final response = await _customerService.updateProfile(payload);

      if (response['success'] == true) {
        // Lấy dữ liệu profile mới từ response (nếu API trả về)
        // Nếu không có thì dùng payload + các field khác giữ nguyên
        final updatedProfile = response['data'] ?? payload;

        // Cập nhật vào local storage
        await _saveProfileToLocal(updatedProfile as Map<String, dynamic>);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );

        context.go(CustomerRouterConfig.homeCustomer);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Không thể cập nhật thông tin'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // LoggerUtils.error('Update profile failed', e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi kết nối, vui lòng thử lại'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải thông tin...',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildFormSection(),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConfig.secondary,
                      ),
                      onPressed: _isUpdating ? null : _updateProfile,
                      child: _isUpdating
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text("Đang cập nhật..."),
                        ],
                      )
                          : const Text("Cập nhật", style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: ColorConfig.white,
      elevation: 0.5,
      shadowColor: Colors.black12,
      title: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConfig.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Cập nhật hồ sơ",
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Thông tin cá nhân",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Cập nhật thông tin của bạn để trải nghiệm tốt hơn",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _buildInputField(
          label: "Họ và tên",
          hint: "Nhập họ và tên của bạn",
          controller: _fullnameController,
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Giới tính",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildGenderChip('female', 'Nữ', Icons.female_rounded),
                const SizedBox(width: 12),
                _buildGenderChip('male', 'Nam', Icons.male_rounded),
                const SizedBox(width: 12),
                _buildGenderChip('other', 'Khác', Icons.transgender_rounded),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInputField(
          label: "Giới thiệu bản thân",
          hint: "Viết đôi điều về bản thân...",
          controller: _bioController,
          icon: Icons.edit_note_rounded,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: ColorConfig.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConfig.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            enabled: !_isUpdating,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderChip(String value, String label, IconData icon) {
    final isSelected = _gender == value;

    return Expanded(
      child: GestureDetector(
        onTap: _isUpdating ? null : () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? ColorConfig.primary : ColorConfig.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? ColorConfig.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: ColorConfig.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? Colors.white : ColorConfig.primary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}