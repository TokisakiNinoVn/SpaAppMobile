import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/user_service.dart';

class EditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? address;
  final String id;
  final bool isDefault;

  const EditAddressScreen({
    super.key,
    this.address,
    required this.id,
    required this.isDefault,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final UserService _userService = UserService();

  final TextEditingController _addressController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    _addressController.text = widget.address?['address'] ?? '';
    _isDefault = widget.isDefault;
  }

  Future<void> _updateAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final bool hasChanges =
        _addressController.text.trim() != (widget.address?['address'] ?? '') ||
            _isDefault != widget.isDefault;

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không có thay đổi nào'),
          backgroundColor: const Color(0xFFF39C12),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
      );
      return;
    }

    final data = {
      'address': _addressController.text.trim(),
      'isDefault': _isDefault,
    };

    setState(() => _isLoading = true);

    try {
      final res = await _userService.updateAddressService(widget.id, data);

      if (res['success'] == true || res['status'] == 'success') {
        SnackBarHelper.showSuccess(context, 'Cập nhật địa chỉ thành công');
        context.pop(true);
      } else {
        SnackBarHelper.showError(context, res['message'] ?? 'Cập nhật thất bại');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress() async {
    context.pop();

    setState(() => _isLoading = true);

    try {
      final res = await _userService.deleteAddressService(widget.id);

      if (res['success'] == true || res['status'] == 'success') {
        SnackBarHelper.showSuccess(context, 'Xóa địa chỉ thành công');
        context.pop(true);
      } else {
        SnackBarHelper.showSuccess(context, res['message'] ?? 'Xóa thất bại');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc muốn xóa địa chỉ này?',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: _deleteAddress,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Chỉnh sửa địa chỉ",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _isLoading ? null : _updateAddress,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: ColorConfig.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Row(
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Address icon header
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    size: 28,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Cập nhật địa chỉ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Thay đổi thông tin địa chỉ của bạn',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),

                const SizedBox(height: 32),

                // Address field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Địa chỉ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                      decoration: InputDecoration(
                        hintText: 'Nhập địa chỉ chi tiết',
                        hintStyle: TextStyle(color: const Color(0xFF666666).withOpacity(0.5)),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorConfig.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Default address switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    title: const Text(
                      'Đặt làm địa chỉ mặc định',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    activeColor: const Color(0xFF27AE60),
                    inactiveThumbColor: const Color(0xFF999999),
                    inactiveTrackColor: const Color(0xFFE0E0E0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                GestureDetector(
                  onTap: _showDeleteConfirmationDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE74C3C).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: const Color(0xFFE74C3C).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.delete_rounded,
                          size: 18,
                          color: Color(0xFFE74C3C),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xóa địa chỉ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFE74C3C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}