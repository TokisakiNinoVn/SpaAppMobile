import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/user_provider.dart'; // Đường dẫn đến file chứa UserProvider

class CreateManagementAccount extends StatefulWidget {
  const CreateManagementAccount({super.key});

  @override
  State<CreateManagementAccount> createState() => _CreateManagementAccountState();
}

class _CreateManagementAccountState extends State<CreateManagementAccount> {
  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullnameController = TextEditingController();

  // Provider instance
  late final UserProvider _userProvider;

  // Selected gender
  String _selectedGender = 'male'; // mặc định: male

  // Lắng nghe provider để cập nhật UI khi isLoading / errorMessage thay đổi
  @override
  void initState() {
    super.initState();
    _userProvider = UserProvider();
    _userProvider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _userProvider.removeListener(_onProviderChanged);
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullnameController.dispose();
    super.dispose();
  }

  // Gửi dữ liệu tạo tài khoản
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Tạo map data theo định dạng yêu cầu
    final Map<String, dynamic> data = {
      "phone": _phoneController.text.trim(),
      "password": _passwordController.text,
      "fullname": _fullnameController.text.trim(),
      "roles": "quanly",
      "gender": _selectedGender,
    };

    // Gọi API qua provider
    final success = await _userProvider.createManagementAccount(data);

    if (!mounted) return;

    if (success) {
      // Thành công: hiển thị thông báo và quay lại
      SnackBarHelper.showSuccess(context, 'Tạo tài khoản thành công!');
      context.pop(); // Quay lại màn hình trước
    } else {
      // Thất bại: hiển thị lỗi từ provider (nếu có)
      if (_userProvider.errorMessage != null) {
        SnackBarHelper.showError(context, _userProvider.errorMessage!);
      } else {
        SnackBarHelper.showSuccess(context, 'Có lỗi xảy ra, vui lòng thử lại sau.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const SizedBox(width: 12),
            const Text("Tạo tài khoản quản lý"),
          ],
        ),
      ),
      body: _userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Số điện thoại
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_android),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (value.length < 10 || value.length > 11) {
                    return 'Số điện thoại không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Họ và tên
              TextFormField(
                controller: _fullnameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Giới tính
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 32),

              // Nút tạo tài khoản
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tạo tài khoản',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}