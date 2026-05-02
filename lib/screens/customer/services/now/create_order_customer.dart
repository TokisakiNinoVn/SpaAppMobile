import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/screens/customer/services/widgets/info_row.dart';
import 'package:spa_app/screens/customer/services/widgets/input_box.dart';
import 'package:spa_app/screens/customer/services/widgets/section.dart';
import 'package:spa_app/services/user_discount_service.dart';
import 'package:spa_app/services/user_service.dart';

import '../../../../helper/format_helper.dart';
import '../../../../helper/logger_utils.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/discount_service.dart';
import '../../../../storage/index.dart';
import '../widgets/address_picker_widget.dart';

enum PaymentMethod {
  zenhome('Ví Zen Home', 'zenhome'),
  cast('Tiền mặt', 'cast'),
  bank('Chuyển khoản', 'bank');

  final String label;
  final String name;
  const PaymentMethod(this.label, this.name);
}

class CreateOrderNowScreen extends StatefulWidget {
  final dynamic data;

  const CreateOrderNowScreen({
    super.key,
    required this.data,
  });

  @override
  State<CreateOrderNowScreen> createState() =>
      _CreateOrderNowScreenState();
}

class _CreateOrderNowScreenState
    extends State<CreateOrderNowScreen> {
  final OrderService _orderService = OrderService();
  final DiscountService _discountService = DiscountService();
  final UserDiscountService _userDiscountService = UserDiscountService();
  final UserService _userService = UserService();

  bool _loading = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshingDiscount = false;
  // bool _isLoadingAddress = false;

  List<Map<String, dynamic>> _addresses = [];
  List<dynamic> _discounts = [];

  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _moneyPrioritizeController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();

  // Focus nodes
  final _noteFocusNode = FocusNode();

  // ===== DISCOUNT STATE =====
  Map<String, dynamic>? _discountData;
  String? _discountError;
  String? _appliedDiscountCode;
  bool _isCheckingCoupon = false;

  // Thanh toán
  PaymentMethod? _paymentMethod;

  int balance = 0;

  // Helper lấy số tiền hỗ trợ thực (loại bỏ định dạng)
  int get _extraFee {
    final text = _moneyPrioritizeController.text;
    if (text.isEmpty) return 0;
    final numericOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numericOnly) ?? 0;
  }

  int get _totalBeforeDiscount => (widget.data['serviceTimePrice']['price'] as int) + _extraFee;

  int get _finalTotal {
    if (_discountData != null) {
      final amountDiscount = _discountData!['amountDiscount'] as int;
      return _totalBeforeDiscount - amountDiscount;
    }
    return _totalBeforeDiscount;
  }

  bool get _isInsufficientBalance {
    if (_paymentMethod != PaymentMethod.zenhome) return false;
    return _finalTotal > balance;
  }

  @override
  void initState() {
    super.initState();
    _paymentMethod = PaymentMethod.zenhome;
    _loadCustomerProfile();
    _loadSavedDiscounts();
    _loadAddresses();
    _noteFocusNode.addListener(_onFocusChange);
    _moneyPrioritizeController.addListener(_formatExtraFeeOnChange);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    _moneyPrioritizeController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  // Format số khi nhập (ví dụ: 1000000 -> 1,000,000)
  void _formatExtraFeeOnChange() {
    final rawText = _moneyPrioritizeController.text;
    final rawDigits = rawText.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawDigits.isEmpty) {
      if (_moneyPrioritizeController.text.isNotEmpty) {
        _moneyPrioritizeController.text = '';
      }
      return;
    }
    final intValue = int.parse(rawDigits);
    final formatted = FormatHelper.formatPrice(intValue).replaceAll(' đ', '');
    if (_moneyPrioritizeController.text != formatted) {
      final cursorPosition = _moneyPrioritizeController.selection.baseOffset;
      _moneyPrioritizeController.text = formatted;
      if (cursorPosition != -1) {
        _moneyPrioritizeController.selection = TextSelection.collapsed(offset: formatted.length);
      }
    }
    // Cập nhật lại discount nếu có mã áp dụng
    if (_appliedDiscountCode != null) _refreshDiscount();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _userService.listAddress();

      if (response['success'] == true || response['status'] == 'success') {
        appLog("List address: ${response['data']}");

        List<dynamic> addressList = response['data'] ?? [];
        setState(() {
          _addresses = addressList.map((addr) => Map<String, dynamic>.from(addr)).toList();
          appLog("List address2: $_addresses");

          // THÊM: Tự động chọn địa chỉ mặc định nếu có
          _selectDefaultAddress();

          _isLoading = false;
        });
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

  void _selectDefaultAddress() {
    if (_addresses.isEmpty) return;

    // Tìm địa chỉ mặc định
    final defaultAddress = _addresses.firstWhere(
          (addr) => addr['isDefault'] == true,
      orElse: () => _addresses.first,
    );

    // Cập nhật controller
    if (defaultAddress['address'] != null && defaultAddress['address'].toString().isNotEmpty) {
      _addressController.text = defaultAddress['address'];
      appLog("Selected default address: ${_addressController.text}");
    } else {
      // Fallback: chọn địa chỉ đầu tiên có address
      final firstValidAddress = _addresses.firstWhere(
            (addr) => addr['address'] != null && addr['address'].toString().isNotEmpty,
        orElse: () => {},
      );
      if (firstValidAddress.isNotEmpty) {
        _addressController.text = firstValidAddress['address'];
      }
    }
  }

  Future<void> _refreshDiscount() async {
    if (_appliedDiscountCode == null || _appliedDiscountCode!.isEmpty) return;
    setState(() => _isRefreshingDiscount = true);
    try {
      final response = await _discountService.checkDiscountService({
        "code": _appliedDiscountCode!,
        "orderValue": _totalBeforeDiscount,
      });
      if (response['success'] == true) {
        setState(() {
          _discountData = response['data'];
          _discountError = null;
        });
      } else {
        _removeDiscount();
        SnackBarHelper.showError(context, response['message'] ?? 'Mã giảm giá không còn áp dụng');
      }
    } catch (e) {
      appLog("Lỗi refresh discount: $e");
    } finally {
      if (mounted) setState(() => _isRefreshingDiscount = false);
    }
  }

  Future<void> _createOrder() async {
    final moneyPrioritize = _extraFee;
    final price = widget.data['serviceTimePrice']['price'] as int;
    final data = {
      'typeOrder': 'order-now',
      "technicianId": widget.data['technician']['id'],
      "serviceTimePriceId": widget.data['serviceTimePrice']['_id'],
      "nameService": widget.data['nameService'],
      "address": _addressController.text.trim(),
      "paymentMethod": _paymentMethod!.name,
      "noteCustomer": _noteController.text.trim(),
      "moneyPrioritize": moneyPrioritize,
      if (_discountData != null)
        'discountInput': {
          "discountId": _discountData!['discountId'],
          "code": _discountData!['code'],
          "typeDiscount": _discountData!['typeDiscount'],
          "value": _discountData!['value'],
          "amountDiscount": _discountData!['amountDiscount'],
        },
    };

    try {
      final response = await _orderService.createOrder(data);
      appLog("response: $response");
      if (response['success'] == true) {
        context.go('/home-customer');
        SnackBarHelper.showSuccess(context, "Tạo yêu cầu đơn thành công! Vui lòng chờ kỹ thuật viên phản hồi!");
        if (_paymentMethod == PaymentMethod.zenhome) {
          int finalPrice = _discountData != null
              ? (_discountData!['orderValueAfterDiscount'] as int)
              : price;
          int newBalance = balance - finalPrice;
          await SharedPrefs.saveValue(PrefType.int, "balance", newBalance);
          setState(() {
            balance = newBalance;
          });
        }
      } else {
        SnackBarHelper.showError(context, response['message'] ?? 'Không thể tạo đơn hàng');
      }
    } catch (e) {
      appLog("Lỗi tạo đơn: ", data: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomerProfile() async {
    try {
      balance = await SharedPrefs.getValue(PrefType.int, "balance") ?? 0;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSavedDiscounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _userDiscountService.listSaveDiscount();
      if (response['status'] == 'success') {
        setState(() {
          _discounts = response['data']['discounts'] ?? [];
          _isLoading = false;
        });
        // appLog("list discount: $_discounts");
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Không thể tải danh sách mã giảm giá';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Đã xảy ra lỗi: $e';
        _isLoading = false;
      });
    }
  }

  // void _showAddressPicker() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       final height = MediaQuery.of(context).size.height * 0.7;
  //
  //       return StatefulBuilder(
  //         builder: (context, setSheetState) {
  //           return Container(
  //             height: height,
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  //             ),
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 10),
  //                 Container(
  //                   width: 40,
  //                   height: 4,
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey.shade300,
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  //                   child: Row(
  //                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                     children: [
  //                       const Text(
  //                         'Chọn địa chỉ',
  //                         style: TextStyle(
  //                           fontSize: 20,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //                       Row(
  //                         children: [
  //                           IconButton(
  //                             onPressed: () async {
  //                               setSheetState(() {
  //                                 _isLoading = true;
  //                               });
  //                               await _loadAddresses();
  //                               setSheetState(() {
  //                                 _isLoading = false;
  //                               });
  //                             },
  //                             icon: Icon(Icons.refresh, color: ColorConfig.primary),
  //                             tooltip: 'Cập nhật danh sách địa chỉ',
  //                           ),
  //
  //                           IconButton(
  //                             onPressed: () async {
  //                               context.push(CustomerRouterConfig.listAddress);
  //                             },
  //                             icon: Icon(Icons.settings, color: ColorConfig.primary),
  //                             tooltip: 'Danh sách địa chỉ',
  //                           ),
  //                         ],
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //                 Expanded(
  //                   child: _isLoading
  //                       ? const Center(child: CircularProgressIndicator())
  //                       : (_addresses.isEmpty)
  //                       ? const Center(
  //                     child: Text(
  //                       'Chưa có địa chỉ nào',
  //                       style: TextStyle(color: Colors.grey),
  //                     ),
  //                   )
  //                       : ListView.builder(
  //                     padding: const EdgeInsets.symmetric(horizontal: 16),
  //                     itemCount: _addresses.length,
  //                     itemBuilder: (context, index) {
  //                       final addr = _addresses[index];
  //                       final isDefault = addr['isDefault'] == true;
  //                       final addressText = addr['address'] ?? 'Địa chỉ không xác định';
  //                       final isSelected = _addressController.text == addressText;
  //
  //                       return AnimatedContainer(
  //                         duration: const Duration(milliseconds: 200),
  //                         margin: const EdgeInsets.only(bottom: 12),
  //                         padding: const EdgeInsets.all(14),
  //                         decoration: BoxDecoration(
  //                           color: isSelected
  //                               ? Colors.blue.withOpacity(0.08)
  //                               : Colors.grey.shade50,
  //                           borderRadius: BorderRadius.circular(16),
  //                           border: Border.all(
  //                             color: isSelected
  //                                 ? ColorConfig.primary
  //                                 : Colors.grey.shade200,
  //                             width: isSelected ? 1.5 : 1,
  //                           ),
  //                         ),
  //                         child: InkWell(
  //                           borderRadius: BorderRadius.circular(16),
  //                           onTap: () {
  //                             setState(() {
  //                               _addressController.text = addr['address'];
  //                             });
  //                             Navigator.pop(context);
  //                           },
  //                           child: Row(
  //                             children: [
  //                               Container(
  //                                 padding: const EdgeInsets.all(10),
  //                                 decoration: BoxDecoration(
  //                                   color: isDefault
  //                                       ? Colors.blue.withOpacity(0.1)
  //                                       : Colors.grey.withOpacity(0.1),
  //                                   shape: BoxShape.circle,
  //                                 ),
  //                                 child: Icon(
  //                                   isDefault
  //                                       ? Icons.home_rounded
  //                                       : Icons.location_on_rounded,
  //                                   color: isDefault
  //                                       ? ColorConfig.primary
  //                                       : Colors.grey,
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 12),
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment: CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(
  //                                       addressText,
  //                                       style: const TextStyle(
  //                                         fontSize: 15,
  //                                         fontWeight: FontWeight.w500,
  //                                       ),
  //                                     ),
  //                                     if (isDefault)
  //                                       Padding(
  //                                         padding: const EdgeInsets.only(top: 4),
  //                                         child: Text(
  //                                           'Mặc định',
  //                                           style: TextStyle(
  //                                             fontSize: 12,
  //                                             color: ColorConfig.textPrimary,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                   ],
  //                                 ),
  //                               ),
  //                               if (isSelected)
  //                                 Icon(
  //                                   Icons.check_circle,
  //                                   color: ColorConfig.primary,
  //                                 ),
  //                             ],
  //                           ),
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //
  //                 if(_addresses.length < 3)...[
  //                   SafeArea(
  //                     child: Padding(
  //                       padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
  //                       child: ElevatedButton.icon(
  //                         onPressed: () {
  //                           context.push(CustomerRouterConfig.addAddress).then((_) {
  //                             _loadAddresses();
  //                           });
  //                         },
  //                         icon: Icon(Icons.add, color: ColorConfig.white),
  //                         label: Text('Thêm địa chỉ mới', style: TextStyle(color: ColorConfig.textWhite)),
  //                         style: ElevatedButton.styleFrom(
  //                           minimumSize: const Size.fromHeight(52),
  //                           elevation: 0,
  //                           backgroundColor: ColorConfig.primary,
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(14),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showAddressPicker() async {
    final selectedAddress = await showAddressPickerSheet(
      context: context,
      initialAddress: _addressController.text,
    );
    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      setState(() {
        _addressController.text = selectedAddress;
      });
    }
  }

  void _showDiscountBottomSheet() {
    final TextEditingController couponController = TextEditingController();
    couponController.text = _appliedDiscountCode ?? '';

    String? localError;
    bool localChecking = false;
    String? selectedDiscountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.7;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Chọn / nhập mã giảm giá',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Mã giảm giá',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              errorText: localError,
                            ),
                            onChanged: (_) {
                              if (localError != null) {
                                setSheetState(() => localError = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: localChecking
                              ? null
                              : () async {
                            final code = couponController.text.trim().toUpperCase();
                            if (code.isEmpty) {
                              setSheetState(() => localError = 'Vui lòng nhập mã');
                              return;
                            }
                            setSheetState(() {
                              localChecking = true;
                              localError = null;
                            });
                            final price = widget.data['serviceTimePrice']['price'] as int;
                            try {
                              final response = await _discountService.checkDiscountService({
                                "code": code,
                                "orderValue": price + _extraFee,
                              });
                              if (response['success'] == true) {
                                setState(() {
                                  _discountData = response['data'];
                                  _appliedDiscountCode = code;
                                  _discountError = null;
                                });
                                if (mounted) Navigator.pop(context);
                              } else {
                                setSheetState(() {
                                  localError = response['message'] ?? 'Mã không hợp lệ';
                                  localChecking = false;
                                });
                              }
                            } catch (e) {
                              appLog("Lỗi kiểm tra mã: ", data: e);
                              setSheetState(() {
                                localError = 'Không thể kiểm tra mã';
                                localChecking = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            foregroundColor: ColorConfig.textWhite,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          ),
                          child: localChecking
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Áp dụng'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Mã của bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Expanded(
                      child: (_discounts.isEmpty)
                          ? const Center(child: Text('Không có mã giảm giá'))
                          : ListView.builder(
                        itemCount: _discounts.length,
                        itemBuilder: (context, index) {
                          final item = _discounts[index];
                          final discount = item['discount'];
                          final code = discount['code'];
                          final int value = discount['value'];
                          final int minOrder = discount['minOrderValue'];
                          final isSelected = selectedDiscountId == item['id'];
                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedDiscountId = item['id'];
                                couponController.text = code;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.amber : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Giảm: ${FormatHelper.formatPrice(value)} đ'),
                                  Text('Đơn tối thiểu: ${FormatHelper.formatPrice(minOrder)} đ'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _removeDiscount() {
    setState(() {
      _discountData = null;
      _appliedDiscountCode = null;
      _discountError = null;
    });
  }

  void _openPaymentSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "Chọn phương thức thanh toán",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...PaymentMethod.values.map((method) {
              final isSelected = _paymentMethod == method;
              IconData icon;
              switch (method) {
                case PaymentMethod.zenhome:
                  icon = Icons.account_balance_wallet;
                  break;
                case PaymentMethod.cast:
                  icon = Icons.money;
                  break;
                case PaymentMethod.bank:
                  icon = Icons.account_balance;
                  break;
              }
              return GestureDetector(
                onTap: () {
                  setState(() => _paymentMethod = method);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.withOpacity(0.08) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.green : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: isSelected ? Colors.green : Colors.black54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          method == PaymentMethod.zenhome
                              ? "${method.label} (Số dư: ${FormatHelper.formatPrice(balance)})"
                              : method.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? ColorConfig.primary : Colors.black87,
                          ),
                        ),
                      ),
                      if (isSelected) Icon(Icons.check_circle, color: ColorConfig.primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool get _canSubmit {
    final hasCoupon = _appliedDiscountCode != null && _appliedDiscountCode!.isNotEmpty;
    final couponValid = _discountData != null;
    return _addressController.text.trim().isNotEmpty &&
        _paymentMethod != null &&
        (!hasCoupon || couponValid) &&
        !_isInsufficientBalance;
  }

  @override
  Widget build(BuildContext context) {
    final technician = widget.data['technician'];
    final service = widget.data['serviceTimePrice'];

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
                decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(40)),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A1A1A)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Xác nhận đặt lịch ngay",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ColorConfig.black),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isInsufficientBalance)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Số dư ví không đủ để thanh toán',
                    style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Tổng tiền", style: TextStyle(color: Colors.grey)),
                        if (_discountData != null) ...[
                          Text(
                            "${FormatHelper.formatPrice(_totalBeforeDiscount)} đ",
                            style: const TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.lineThrough),
                          ),
                          Text(
                            "${FormatHelper.formatPrice(_finalTotal)} đ",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ] else
                          Text(
                            "${FormatHelper.formatPrice(_totalBeforeDiscount)} đ",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  if (_isInsufficientBalance && _paymentMethod == PaymentMethod.zenhome)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          context.push(CustomerRouterConfig.choosePackage);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConfig.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Nạp tiền"),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _canSubmit ? _createOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canSubmit ? ColorConfig.primary : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Đặt ngay"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: [
            // Thông tin dịch vụ + kỹ thuật viên (giữ nguyên)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data['nameService'],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: ColorConfig.textBlack.withOpacity(.4)),
                      const SizedBox(width: 4),
                      Text(
                        "${service['duration']} phút",
                        style: TextStyle(fontSize: 13, color: ColorConfig.textBlack.withOpacity(.5)),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 12, color: Colors.black.withOpacity(.08)),
                      const SizedBox(width: 10),
                      Icon(Icons.local_offer_outlined, size: 14, color: ColorConfig.textBlack.withOpacity(.4)),
                      const SizedBox(width: 4),
                      Text(
                        "${FormatHelper.formatPrice(widget.data['serviceTimePrice']['price'])} đ",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ColorConfig.textBlack.withOpacity(.6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(.08), Colors.transparent]))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black.withOpacity(.08))),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(FormatHelper.formatNetworkImageUrl(technician['avatar']['url'])),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(FormatHelper.formatNameTechnician(technician['fullName']), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text("${technician['rate']}", style: TextStyle(fontSize: 13, color: ColorConfig.textBlack.withOpacity(.6))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ========== CARD GỘP 4 MỤC ==========
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  // 1. Địa chỉ của bạn
                  _buildInfoRowWithButton(
                    label: 'Địa chỉ của bạn',
                    value: _addressController.text.isEmpty ? 'Chưa có địa chỉ' : _addressController.text,
                    onTap: _showAddressPicker,
                    buttonLabel: _addressController.text.isEmpty ? 'Chọn' : 'Thay đổi',
                  ),
                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
                  _buildInfoRowWithButton(
                    label: 'Phương thức thanh toán',
                    value: _paymentMethod?.label ?? 'Chưa chọn',
                    onTap: _openPaymentSelector,
                    buttonLabel: _paymentMethod == null ? 'Chọn' : 'Thay đổi',
                  ),
                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

                  _buildDiscountRow(),
                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text('Phí hỗ trợ thêm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Khoản tiền hỗ trợ thêm cho kỹ thuật viên (không bắt buộc)',
                              child: Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _moneyPrioritizeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nhập số tiền',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            ),
                            onChanged: (_) {
                              setState(() {});
                              if (_appliedDiscountCode != null) _refreshDiscount();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Chi tiết thanh toán
            Section(
              title: "Chi tiết thanh toán",
              child: Column(
                children: [
                  InfoRow("Giá dịch vụ", "${FormatHelper.formatPrice(widget.data['serviceTimePrice']['price'])} đ"),
                  if (_extraFee > 0)
                    InfoRow("Phí hỗ trợ thêm", "+${FormatHelper.formatPrice(_extraFee)} đ", valueStyle: const TextStyle(color: Colors.green)),
                  if (_discountData != null)
                    InfoRow(
                      "Giảm giá",
                      "- ${_discountData!['typeDiscount'] == 'percentage' ? '${_discountData!['value']}%' : FormatHelper.formatPrice(_discountData!['value'] as int) + ' đ'}",
                      valueStyle: const TextStyle(color: Colors.red),
                    ),
                  const Divider(height: 20),
                  InfoRow("Tổng cộng", "${FormatHelper.formatPrice(_finalTotal)} đ", valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Ghi chú
            Section(
              title: "Ghi chú",
              child: InputBox(
                isFocused: _noteFocusNode.hasFocus,
                child: TextField(
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Ví dụ: Thời gian phù hợp, tình trạng cụ thể, lưu ý khi đến…",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  // Widget hỗ trợ: dòng có label, value và nút thay đổi/chọn
  Widget _buildInfoRowWithButton({
    required String label,
    required String value,
    required VoidCallback onTap,
    required String buttonLabel,
  }) {
    final isEmpty = value.contains('Chưa');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HÀNG 1: LABEL + BUTTON =====
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    buttonLabel,
                    style: TextStyle(
                      color: ColorConfig.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            // ===== HÀNG 2: VALUE =====
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dòng mã giảm giá đặc biệt (hiển thị thông tin mã và nút kèm xoá)
  Widget _buildDiscountRow() {
    final isApplied = _discountData != null;

    final discountText = isApplied
        ? (_discountData!['typeDiscount'] == 'percentage'
        ? '${_discountData!['value']}%'
        : '${FormatHelper.formatPrice(_discountData!['value'] as int)} đ')
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== DÒNG 1: TITLE =====
          const Text(
            'Mã giảm giá',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 6),

          // ===== DÒNG 2: CONTENT =====
          Row(
            children: [
              Expanded(
                child: isApplied
                    ? Row(
                  children: [
                    Flexible(
                      child: Text(
                        _appliedDiscountCode!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.grey)),

                    const SizedBox(width: 6),
                    Text(
                      'Giảm $discountText',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Chưa áp dụng mã',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),

              // ===== ACTIONS =====
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isApplied)
                    InkWell(
                      onTap: _removeDiscount,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),

                  const SizedBox(width: 4),

                  TextButton(
                    onPressed: _showDiscountBottomSheet,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isApplied ? 'Thay đổi' : 'Chọn',
                      style: TextStyle(
                        color: ColorConfig.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}