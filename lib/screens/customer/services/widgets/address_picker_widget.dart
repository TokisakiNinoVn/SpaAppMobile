// lib/widgets/address_picker_widget.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/user_service.dart';

/// Widget chọn địa chỉ, có thể dùng độc lập hoặc gọi qua showModalBottomSheet
class AddressPickerWidget extends StatefulWidget {
  final String? initialAddress;
  final Function(String)? onAddressSelected;

  const AddressPickerWidget({
    super.key,
    this.initialAddress,
    this.onAddressSelected,
  });

  @override
  State<AddressPickerWidget> createState() => _AddressPickerWidgetState();
}

class _AddressPickerWidgetState extends State<AddressPickerWidget> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _addresses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress ?? '';
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _userService.listAddress();
      if (response['success'] == true || response['status'] == 'success') {
        List<dynamic> addressList = response['data'] ?? [];
        setState(() {
          _addresses = addressList
              .map((addr) => Map<String, dynamic>.from(addr))
              .toList();
          _selectDefaultAddressIfNeeded();
          _isLoading = false;
        });
        // appLog("Đã tải ${_addresses.length} địa chỉ");
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Không thể tải danh sách địa chỉ';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _selectDefaultAddressIfNeeded() {
    // Nếu đã có địa chỉ được chọn trước đó thì giữ nguyên
    if (_selectedAddress != null && _selectedAddress!.isNotEmpty) return;
    if (_addresses.isEmpty) return;

    // Tìm địa chỉ mặc định
    final defaultAddress = _addresses.firstWhere(
          (addr) => addr['isDefault'] == true,
      orElse: () => _addresses.first,
    );

    if (defaultAddress['address'] != null &&
        defaultAddress['address'].toString().isNotEmpty) {
      setState(() {
        _selectedAddress = defaultAddress['address'];
      });
    } else {
      // Fallback: địa chỉ đầu tiên có nội dung
      final firstValid = _addresses.firstWhere(
            (addr) => addr['address'] != null && addr['address'].toString().isNotEmpty,
        orElse: () => {},
      );
      if (firstValid.isNotEmpty) {
        setState(() {
          _selectedAddress = firstValid['address'];
        });
      }
    }
  }

  void _selectAddress(String address) {
    setState(() {
      _selectedAddress = address;
    });
    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(address);
    }
    // Nếu widget được dùng trong showModalBottomSheet, đóng và trả về giá trị
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn địa chỉ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        await _loadAddresses();
                        setState(() => _isLoading = false);
                      },
                      icon: Icon(Icons.refresh, color: ColorConfig.primary),
                      tooltip: 'Cập nhật danh sách địa chỉ',
                    ),
                    IconButton(
                      onPressed: () async {
                        // Điều hướng đến màn hình danh sách địa chỉ (tuỳ router)
                        await context.push(CustomerRouterConfig.listAddress);
                        // Sau khi quay lại, tải lại danh sách
                        _loadAddresses();
                      },
                      icon: Icon(Icons.settings, color: ColorConfig.primary),
                      tooltip: 'Quản lý địa chỉ',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAddresses,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
                : _addresses.isEmpty
                ? const Center(
              child: Text(
                'Chưa có địa chỉ nào',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                final isDefault = addr['isDefault'] == true;
                final addressText =
                    addr['address'] ?? 'Địa chỉ không xác định';
                final isSelected = _selectedAddress == addressText;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.08)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? ColorConfig.primary
                          : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _selectAddress(addressText),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDefault
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDefault
                                ? Icons.home_rounded
                                : Icons.location_on_rounded,
                            color: isDefault
                                ? ColorConfig.primary
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                addressText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isDefault)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Mặc định',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: ColorConfig.textPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: ColorConfig.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_addresses.length < 3)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.push(CustomerRouterConfig.addAddress);
                    // Sau khi thêm mới, tải lại danh sách
                    _loadAddresses();
                  },
                  icon: Icon(Icons.add, color: ColorConfig.white),
                  label: Text(
                    'Thêm địa chỉ mới',
                    style: TextStyle(color: ColorConfig.textWhite),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    elevation: 0,
                    backgroundColor: ColorConfig.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hàm tiện ích để hiển thị bottom sheet chọn địa chỉ
/// Trả về địa chỉ được chọn, hoặc null nếu đóng mà không chọn
Future<String?> showAddressPickerSheet({
  required BuildContext context,
  String? initialAddress,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddressPickerWidget(
      initialAddress: initialAddress,
    ),
  );
}