import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/user_service.dart';

class ListAddressScreen extends StatefulWidget {
  const ListAddressScreen({
    super.key,
  });

  @override
  State<ListAddressScreen> createState() => _ListAddressScreenState();
}

class _ListAddressScreenState extends State<ListAddressScreen> {
  final UserService _userService = UserService();
  List<dynamic> _addresses = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Future<void> _loadAddresses() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });
  //
  //   try {
  //     final response = await _userService.listAddress();
  //
  //     if (response['success'] == true || response['status'] == 'success') {
  //       setState(() {
  //         _addresses = response['data'] ?? [];
  //         _isLoading = false;
  //       });
  //     } else {
  //       setState(() {
  //         _errorMessage = response['message'] ?? 'Không thể tải danh sách địa chỉ';
  //         _isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Lỗi kết nối: ${e.toString()}';
  //       _isLoading = false;
  //     });
  //   }
  // }

  Future<void> _loadAddresses({bool isRefresh = false}) async {
    if (!mounted) return;

    setState(() {
      if (isRefresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }

      _errorMessage = null;
    });

    try {
      final response = await _userService.listAddress();

      if (!mounted) return;

      if (response['success'] == true ||
          response['status'] == 'success') {
        setState(() {
          _addresses = response['data'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Không thể tải danh sách địa chỉ';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // Future<void> _onRefresh() async {
  //   setState(() {
  //     _isRefreshing = true;
  //   });
  //
  //   try {
  //     final response = await _userService.listAddress();
  //
  //     if (response['success'] == true || response['status'] == 'success') {
  //       setState(() {
  //         _addresses = response['data'] ?? [];
  //         _errorMessage = null;
  //       });
  //     } else {
  //       setState(() {
  //         _errorMessage = response['message'] ?? 'Không thể tải danh sách địa chỉ';
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _errorMessage = 'Lỗi kết nối: ${e.toString()}';
  //     });
  //   } finally {
  //     setState(() {
  //       _isRefreshing = false;
  //     });
  //   }
  // }

  Future<void> _onRefresh() async {
    await _loadAddresses(isRefresh: true);
  }

  Future<void> _deleteAddress(String id, String address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa địa chỉ này?',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await _userService.deleteAddressService(id);

      if (response['success'] == true || response['status'] == 'success') {
        _loadAddresses();
        SnackBarHelper.showSuccess(context, "Xóa địa chỉ thành công!");
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Xóa địa chỉ thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: ${e.toString()}');
    }
  }

  Future<void> _setDefaultAddress(String id) async {
    try {
      final response = await _userService.setDefaultAddressService(id, {});
      // appLog("response dat lai dia chi: $response");

      if (response['success'] == true || response['status'] == 'success') {
        _loadAddresses();
        SnackBarHelper.showSuccess(context, 'Đặt địa chỉ mặc định thành công!');
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Đặt địa chỉ mặc định thất bại');
      }
    } catch (e) {
      SnackBarHelper.showError(context, 'Lỗi: ${e.toString()}');
    }
  }

  Future<void> _navigateToAddAddress() async {
    final result = await context.push(CustomerRouterConfig.addAddress);

    if (result == true && mounted) {
      _loadAddresses();
    }
  }

  Future<void> _navigateToEditAddress(Map<String, dynamic> address) async {
    final result = await context.push(
      CustomerRouterConfig.editAddress,
      extra: {
        "id": address["id"],
        "isDefault": address["isDefault"] ?? false,
        "address": address,
      },
    );

    if (result == true && mounted) {
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: ColorConfig.primaryBackground,
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
                "Địa chỉ của tôi",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            InkWell(
              onTap: _navigateToAddAddress,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF1A1A1A),
        backgroundColor: Colors.white,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: const Color(0xFF666666)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAddresses,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 64, color: const Color(0xFF666666)),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa có địa chỉ nào',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn vào nút + để thêm địa chỉ mới',
              style: TextStyle(fontSize: 13, color: const Color(0xFF666666).withOpacity(0.6)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final String id = address['id']?.toString() ?? '';
        final String addressText = address['address'] ?? '';
        final bool isDefault = address['isDefault'] == true;

        return _buildAddressCard(
          id: id,
          address: addressText,
          isDefault: isDefault,
        );
      },
    );
  }

  Widget _buildAddressCard({
    required String id,
    required String address,
    required bool isDefault,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDefault ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: isDefault ? const Color(0xFF27AE60) : const Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        if (isDefault) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Text(
                              'Mặc định',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF27AE60),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Menu icon
                  PopupMenuButton<String>(
                    color: ColorConfig.white,
                    icon: const Icon(Icons.more_vert, color: Color(0xFF666666), size: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    onSelected: (value) async {
                      switch (value) {
                        case 'edit':
                          final addressData = _addresses.firstWhere(
                                (a) => a['id'].toString() == id,
                            orElse: () => {},
                          );
                          _navigateToEditAddress(addressData);
                          break;
                        case 'delete':
                          _deleteAddress(id, address);
                          break;
                        case 'set_default':
                          if (!isDefault) {
                            _setDefaultAddress(id);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A1A1A)),
                            SizedBox(width: 12),
                            Text('Chỉnh sửa', style: TextStyle(color: Color(0xFF1A1A1A))),
                          ],
                        ),
                      ),
                      if (!isDefault)
                        const PopupMenuItem(
                          value: 'set_default',
                          child: Row(
                            children: [
                              Icon(Icons.star_border_outlined, size: 18, color: Color(0xFF1A1A1A)),
                              SizedBox(width: 12),
                              Text('Đặt mặc định', style: TextStyle(color: Color(0xFF1A1A1A))),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Color(0xFFE74C3C)),
                            SizedBox(width: 12),
                            Text('Xóa', style: TextStyle(color: Color(0xFFE74C3C))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons for non-default addresses
            if (!isDefault)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      label: 'Sửa',
                      onTap: () {
                        final addressData = _addresses.firstWhere(
                              (a) => a['id'].toString() == id,
                          orElse: () => {},
                        );
                        _navigateToEditAddress(addressData);
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.star_border_outlined,
                      label: 'Mặc định',
                      onTap: () => _setDefaultAddress(id),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.delete_outline,
                      label: 'Xóa',
                      onTap: () => _deleteAddress(id, address),
                      color: const Color(0xFFE74C3C),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF666666),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}