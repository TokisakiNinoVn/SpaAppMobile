import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/providers/user_provider.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/screens/customer/services/widgets/address_picker_widget.dart';
import 'package:spa_app/screens/customer/services/widgets/discount_bottom_sheet.dart';
import 'package:spa_app/screens/customer/services/widgets/info_row.dart';
import 'package:spa_app/screens/customer/services/widgets/input_box.dart';
import 'package:spa_app/screens/customer/services/widgets/section.dart';
import 'package:spa_app/services/user_discount_service.dart';

import '../../../../helper/format_helper.dart';
import '../../../../helper/logger_utils.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/discount_service.dart';
import '../../../../storage/index.dart';

// Định nghĩa phương thức thanh toán
enum PaymentMethod {
  zenhome('Ví Zen Home', 'zenhome'),
  cast('Tiền mặt', 'cast'),
  bank('Chuyển khoản', 'bank');

  final String label;
  final String name;
  const PaymentMethod(this.label, this.name);
}

class CreateAutoMatchingOrderScreen extends StatefulWidget {
  final dynamic data;

  const CreateAutoMatchingOrderScreen({
    super.key,
    required this.data,
  });

  @override
  State<CreateAutoMatchingOrderScreen> createState() => _CreateAutoMatchingOrderScreenState();
}

class _CreateAutoMatchingOrderScreenState
    extends State<CreateAutoMatchingOrderScreen> {
  final OrderService _orderService = OrderService();
  final DiscountService _discountService = DiscountService();
  final UserDiscountService _userDiscountService = UserDiscountService();

  bool _loading = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshingDiscount = false;
  // Loại thời gian đặt: 'now' hoặc 'book'
  String _timeType = 'now'; // Mặc định 'Đặt ngay'

  // Danh sách địa chỉ từ profile
  List<Map<String, dynamic>> _addresses = [];
  List<dynamic> _discounts = [];

  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  final _moneyPrioritizeController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 75));

  // Focus nodes
  final _noteFocusNode = FocusNode();

  // ===== DISCOUNT STATE =====
  Map<String, dynamic>? _discountData; // data khi mã hợp lệ
  String? _discountError; // lỗi hiển thị tạm thời (không dùng nhiều)
  String? _appliedDiscountCode; // mã đã được áp dụng thành công
  bool _isCheckingCoupon = false;
  bool _isCreatingOrder = false;

  // Thanh toán
  PaymentMethod? _paymentMethod;

  int balance = 0;

  @override
  void initState() {
    super.initState();
    // appLog("Data widget: ${widget.data}");
    _paymentMethod = PaymentMethod.zenhome;
    _loadCustomerProfile();
    _loadDiscounts();
    _noteFocusNode.addListener(_onFocusChange);
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

  int get _extraFee => int.tryParse(_moneyPrioritizeController.text.trim()) ?? 0;

  int get _totalBeforeDiscount => (widget.data['timePrice']['price'] as int) + _extraFee;

  int get _finalTotal {
    if (_discountData != null) {
      final amountDiscount = _discountData!['amountDiscount'] as int;
      return _totalBeforeDiscount - amountDiscount;
    }
    return _totalBeforeDiscount;
  }

  Future<void> _loadDiscounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _discountService.listPublic();
      // appLog("${response}");
      // appLog("${response['data']}");
      if (response['success'] == true) {
        setState(() {
          _discounts = response['data'] ?? [];
          // appLog("${_discounts}");
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

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(minutes: 60)),
      firstDate: now.add(const Duration(minutes: 60)), // Tối thiểu 60p
      lastDate: now.add(const Duration(days: 7)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: ColorConfig.primary),
          ),
          child: child!,
        );
      },
    );
    if (date == null) return;

    // Giới hạn time picker cũng từ 60p trở đi
    final minTime = now.add(const Duration(minutes: 60));
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minTime),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: ColorConfig.primary),
          ),
          child: child!,
        );
      },
    );
    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );

    // Kiểm tra lại điều kiện >=60p và <=7 ngày
    if (selectedDateTime.isBefore(now.add(const Duration(minutes: 60)))) {
      _showInvalidTimeDialog('Thời gian đặt trước phải sau thời điểm hiện tại ít nhất 60 phút.');
      return;
    }
    if (selectedDateTime.isAfter(now.add(const Duration(days: 7)))) {
      _showInvalidTimeDialog('Thời gian đặt trước không được quá 7 ngày.');
      return;
    }

    setState(() => _selectedDateTime = selectedDateTime);
  }

// Helper hiển thị dialog lỗi (thêm method mới)
  void _showInvalidTimeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thời gian không hợp lệ"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  bool get _isInsufficientBalance {
    if (_paymentMethod != PaymentMethod.zenhome) return false;
    return _finalTotal > balance;
  }

  bool _isPastTime(DateTime selectedTime) {
    return selectedTime.isBefore(DateTime.now());
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
        // Nếu mã không còn hiệu lực, xóa discount
        _removeDiscount();
        SnackBarHelper.showError(context, response['message'] ?? 'Mã giảm giá không còn áp dụng');
      }
    } catch (e) {
      appLog("Lỗi refresh discount: $e");
    } finally {
      if (mounted) setState(() => _isRefreshingDiscount = false);
    }
  }

  // Future<void> _createOrder() async {
  //   final moneyPrioritizeRaw = _moneyPrioritizeController.text.trim();
  //   final moneyPrioritize = moneyPrioritizeRaw.isEmpty ? 0 : int.tryParse(moneyPrioritizeRaw) ?? 0;
  //   final price = widget.data['timePrice']['price'] as int;
  //   final data = {
  //     'typeOrder': 'automatic-matching',
  //     "serviceTimePriceId": widget.data['timePrice']['_id'],
  //     "nameService": widget.data['service']['name'],
  //     "address": _addressController.text.trim(),
  //     "paymentMethod": _paymentMethod!.name,
  //     "noteCustomer": _noteController.text.trim(),
  //     "moneyPrioritize": moneyPrioritize,
  //     'workingHours': _formatWorkingHours(_selectedDateTime),
  //     "typeTime": _timeType,
  //     'subTypeOrder': _timeType,
  //
  //     if (_discountData != null)
  //       'discountInput': {
  //         "discountId": _discountData!['discountId'],
  //         "code": _discountData!['code'],
  //         "typeDiscount": _discountData!['typeDiscount'],
  //         "value": _discountData!['value'],
  //         "amountDiscount": _discountData!['amountDiscount'],
  //       },
  //   };
  //
  //   try {
  //     final response = await _orderService.createOrder(data);
  //     appLog("response: $response");
  //     if (response['success'] == true) {
  //       context.go('/home-customer');
  //       SnackBarHelper.showSuccess(context, "Tạo yêu cầu đơn thành công! Vui lòng chờ kỹ thuật viên phản hồi!");
  //       // Cập nhật số dư ví nếu thanh toán bằng Ví Zen Home
  //       if (_paymentMethod == PaymentMethod.zenhome) {
  //         int finalPrice = _discountData != null
  //             ? (_discountData!['orderValueAfterDiscount'] as int)
  //             : price;
  //         int newBalance = balance - finalPrice;
  //         await SharedPrefs.saveValue(PrefType.int, "balance", newBalance);
  //         setState(() {
  //           balance = newBalance;
  //         });
  //       }
  //     } else {
  //       SnackBarHelper.showError(context, response['message'] ?? 'Không thể tạo đơn hàng');
  //     }
  //   } catch (e) {
  //     appLog("Lỗi tạo đơn: ", data: e);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(e.toString()),
  //           backgroundColor: Colors.red,
  //           behavior: SnackBarBehavior.floating,
  //         ),
  //       );
  //     }
  //   }
  // }


  Future<void> _createOrder() async {
    // Chặn nếu đang tạo đơn
    if (_isCreatingOrder) return;

    setState(() => _isCreatingOrder = true);

    final moneyPrioritizeRaw = _moneyPrioritizeController.text.trim();
    final moneyPrioritize = moneyPrioritizeRaw.isEmpty ? 0 : int.tryParse(moneyPrioritizeRaw) ?? 0;
    final price = widget.data['timePrice']['price'] as int;
    final data = {
      'typeOrder': 'automatic-matching',
      "serviceTimePriceId": widget.data['timePrice']['_id'],
      "nameService": widget.data['service']['name'],
      "address": _addressController.text.trim(),
      "paymentMethod": _paymentMethod!.name,
      "noteCustomer": _noteController.text.trim(),
      "moneyPrioritize": moneyPrioritize,
      'workingHours': _formatWorkingHours(_selectedDateTime),
      "typeTime": _timeType,
      'subTypeOrder': _timeType,

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
        // Cập nhật số dư ví nếu thanh toán bằng Ví Zen Home
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
    } finally {
      if (mounted) setState(() => _isCreatingOrder = false);
    }
  }

  Future<void> _loadCustomerProfile() async {
    final provider = context.read<UserProvider>();
    try {
      await provider.loadBalanceUser();
      balance = provider.nowBalance;

      // balance = await SharedPrefs.getValue(PrefType.int, "balance") ?? 0;
      final rawProfile = await SharedPrefs.getValue(PrefType.string, "customerProfile");
      // appLog("data Profile: $rawProfile");
      if (rawProfile != null) {
        final profile = jsonDecode( rawProfile);
        // Lấy danh sách địa chỉ
        List<dynamic> addressList = profile['address'] ?? [];
        _addresses = addressList.map((addr) => Map<String, dynamic>.from(addr)).toList();

        // Tìm địa chỉ mặc định
        final defaultAddress = _addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
          orElse: () => _addresses.isNotEmpty ? _addresses.first : {},
        );
        if (defaultAddress.isNotEmpty) {
          _addressController.text = defaultAddress['address'] ?? '';
        } else if (_addresses.isNotEmpty) {
          _addressController.text = _addresses.first['address'] ?? '';
        }
      }
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

  // Mở bottom sheet chọn địa chỉ
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
  //
  //                 const Padding(
  //                   padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
  //                   child: Row(
  //                     children: [
  //                       Text(
  //                         'Chọn địa chỉ',
  //                         style: TextStyle(
  //                           fontSize: 20,
  //                           fontWeight: FontWeight.w700,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //
  //                 /// 🔥 LIST ĐỊA CHỈ
  //                 Expanded(
  //                   child: (_addresses.isEmpty)
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
  //                       final isSelected =
  //                           _addressController.text == addr['address'];
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
  //                               _addressController.text =
  //                               addr['address'];
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
  //
  //                               const SizedBox(width: 12),
  //
  //                               /// TEXT
  //                               Expanded(
  //                                 child: Column(
  //                                   crossAxisAlignment:
  //                                   CrossAxisAlignment.start,
  //                                   children: [
  //                                     Text(
  //                                       addr['address'],
  //                                       style: const TextStyle(
  //                                         fontSize: 15,
  //                                         fontWeight: FontWeight.w500,
  //                                       ),
  //                                     ),
  //                                     if (isDefault)
  //                                       Padding(
  //                                         padding:
  //                                         EdgeInsets.only(top: 4),
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
  //
  //                               /// CHECK
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
  //                 /// 👇 BUTTON
  //                 SafeArea(
  //                   child: Padding(
  //                     padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
  //                     child: ElevatedButton.icon(
  //                       onPressed: () {
  //                         context.push(CustomerRouterConfig.addAddress);
  //                       },
  //                       icon: Icon(Icons.add, color: ColorConfig.white,),
  //                       label: Text('Thêm địa chỉ mới', style: TextStyle(color: ColorConfig.textWhite),),
  //                       style: ElevatedButton.styleFrom(
  //                         minimumSize: const Size.fromHeight(52),
  //                         elevation: 0,
  //                         backgroundColor: ColorConfig.primary,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(14),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
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

  // Thay _showDiscountBottomSheet() cũ bằng:
  void _showDiscountBottomSheet() async {
    final result = await showDiscountBottomSheet(
      context: context,
      orderValue: _totalBeforeDiscount,
      discounts: _discounts,
      appliedCode: _appliedDiscountCode,
    );
    if (result != null) {
      setState(() {
        _discountData = result.data;
        _appliedDiscountCode = result.code;
        _discountError = null;
      });
    }
  }

  // Mở bottom sheet nhập mã giảm giá
  // void _showDiscountBottomSheet() {
  //   final TextEditingController couponController = TextEditingController();
  //   couponController.text = _appliedDiscountCode ?? '';
  //
  //   String? localError;
  //   bool localChecking = false;
  //   String? selectedDiscountId;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       final height = MediaQuery.of(context).size.height * 0.7;
  //
  //       return StatefulBuilder(
  //         builder: (context, setSheetState) {
  //           return SizedBox(
  //             height: height,
  //             child: Padding(
  //               padding: const EdgeInsets.all(20),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.stretch,
  //                 children: [
  //                   const Text(
  //                     'Chọn / nhập mã giảm giá',
  //                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //                     textAlign: TextAlign.center,
  //                   ),
  //
  //                   const SizedBox(height: 10),
  //                   Row(
  //                     children: [
  //                       Expanded(
  //                         child: TextField(
  //                           controller: couponController,
  //                           textCapitalization: TextCapitalization.characters,
  //                           style: const TextStyle(
  //                             fontSize: 14,
  //                           ),
  //                           decoration: InputDecoration(
  //                             hintText: 'Mã giảm giá',
  //                             isDense: true,
  //                             contentPadding: const EdgeInsets.symmetric(
  //                               vertical: 10,
  //                               horizontal: 12,
  //                             ),
  //                             border: OutlineInputBorder(
  //                               borderRadius: BorderRadius.circular(30),
  //                             ),
  //                             enabledBorder: OutlineInputBorder(
  //                               borderRadius: BorderRadius.circular(30),
  //                             ),
  //                             focusedBorder: OutlineInputBorder(
  //                               borderRadius: BorderRadius.circular(30),
  //                             ),
  //                             errorText: localError,
  //                           ),
  //                           onChanged: (_) {
  //                             if (localError != null) {
  //                               setSheetState(() => localError = null);
  //                             }
  //                           },
  //                         ),
  //                       ),
  //
  //                       const SizedBox(width: 10),
  //                       ElevatedButton(
  //                         onPressed: localChecking
  //                             ? null
  //                             : () async {
  //                           final code = couponController.text
  //                               .trim()
  //                               .toUpperCase();
  //
  //                           if (code.isEmpty) {
  //                             setSheetState(() =>
  //                             localError = 'Vui lòng nhập mã');
  //                             return;
  //                           }
  //
  //                           setSheetState(() {
  //                             localChecking = true;
  //                             localError = null;
  //                           });
  //
  //                           final price = (widget.data[
  //                           'serviceTimePrice']['price'] as int);
  //
  //                           try {
  //                             final response =
  //                             await _discountService
  //                                 .checkDiscountService({
  //                               "code": code,
  //                               "orderValue": price,
  //                             });
  //
  //                             if (response['success'] == true) {
  //                               setState(() {
  //                                 _discountData = response['data'];
  //                                 _appliedDiscountCode = code;
  //                                 _discountError = null;
  //                               });
  //
  //                               if (mounted) Navigator.pop(context);
  //                             } else {
  //                               setSheetState(() {
  //                                 localError = response['message'] ??
  //                                     'Mã không hợp lệ';
  //                                 localChecking = false;
  //                               });
  //                             }
  //                           } catch (e) {
  //                             appLog("Lỗi kiểm tra mã: ", data: e);
  //                             setSheetState(() {
  //                               localError =
  //                               'Không thể kiểm tra mã';
  //                               localChecking = false;
  //                             });
  //                           }
  //                         },
  //                         style: ElevatedButton.styleFrom(
  //                           backgroundColor: ColorConfig.primary,
  //                           foregroundColor: ColorConfig.textWhite,
  //                           padding: const EdgeInsets.symmetric(
  //                               horizontal: 16, vertical: 7),
  //                         ),
  //                         child: localChecking
  //                             ? const SizedBox(
  //                           width: 18,
  //                           height: 18,
  //                           child:
  //                           CircularProgressIndicator(strokeWidth: 2),
  //                         )
  //                             : const Text('Áp dụng'),
  //                       ),
  //                     ],
  //                   ),
  //
  //                   const SizedBox(height: 20),
  //
  //                   /// 🔥 LIST DISCOUNT
  //                   const Text(
  //                     'Mã của bạn',
  //                     style: TextStyle(
  //                         fontSize: 16, fontWeight: FontWeight.w600),
  //                   ),
  //
  //                   const SizedBox(height: 10),
  //
  //                   Expanded(
  //                     child: (_discounts == null || _discounts.isEmpty)
  //                         ? const Center(
  //                       child: Text('Không có mã giảm giá'),
  //                     )
  //                         : ListView.builder(
  //                       itemCount: _discounts.length,
  //                       itemBuilder: (context, index) {
  //                         final item = _discounts[index];
  //                         final discount = item['discount'];
  //
  //                         final code = discount['code'];
  //                         final int value = discount['value'];
  //                         final int minOrder = discount['minOrderValue'];
  //
  //                         final isSelected =
  //                             selectedDiscountId == item['id'];
  //
  //                         return GestureDetector(
  //                           onTap: () {
  //                             setSheetState(() {
  //                               selectedDiscountId = item['id'];
  //                               couponController.text = code;
  //                             });
  //                           },
  //                           child: Container(
  //                             margin:
  //                             const EdgeInsets.only(bottom: 10),
  //                             padding: const EdgeInsets.all(12),
  //                             decoration: BoxDecoration(
  //                               borderRadius:
  //                               BorderRadius.circular(12),
  //                               border: Border.all(
  //                                 color: isSelected
  //                                     ? Colors.amber
  //                                     : Colors.grey.shade300,
  //                                 width: isSelected ? 2 : 1,
  //                               ),
  //                             ),
  //                             child: Column(
  //                               crossAxisAlignment:
  //                               CrossAxisAlignment.start,
  //                               children: [
  //                                 Text(
  //                                   code,
  //                                   style: const TextStyle(
  //                                     fontWeight: FontWeight.bold,
  //                                     fontSize: 16,
  //                                   ),
  //                                 ),
  //                                 const SizedBox(height: 4),
  //                                 Text(
  //                                     'Giảm: ${FormatHelper.formatPrice(value)} đ'),
  //                                 Text(
  //                                     'Đơn tối thiểu: ${FormatHelper.formatPrice(minOrder)} đ'),
  //                               ],
  //                             ),
  //                           ),
  //                         );
  //                       },
  //                     ),
  //                   ),
  //
  //                   const SizedBox(height: 10),
  //
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: const Text('Hủy'),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _removeDiscount() {
    setState(() {
      _discountData = null;
      _appliedDiscountCode = null;
      _discountError = null;
    });
  }

  // bool get _canSubmit {
  //   final hasCoupon = _appliedDiscountCode != null && _appliedDiscountCode!.isNotEmpty;
  //   final couponValid = _discountData != null;
  //   return _addressController.text.trim().isNotEmpty &&
  //       _paymentMethod != null &&
  //       (!hasCoupon || couponValid) &&
  //       !_isInsufficientBalance; // Thêm điều kiện kiểm tra số dư
  // }

  bool get _canSubmit {
    final hasCoupon = _appliedDiscountCode != null && _appliedDiscountCode!.isNotEmpty;
    final couponValid = _discountData != null;
    final addressValid = _addressController.text.trim().isNotEmpty;
    final paymentValid = _paymentMethod != null;
    final balanceValid = !_isInsufficientBalance;
    final timeValid = _isValidBookingTime;   // Thêm dòng này
    return addressValid && paymentValid && timeValid && (!hasCoupon || couponValid) && balanceValid;
  }

  bool get _isValidBookingTime {
    if (_timeType != 'book') return true;
    final now = DateTime.now();
    final minTime = now.add(const Duration(minutes: 60));
    final maxTime = now.add(const Duration(days: 7));
    return _selectedDateTime.isAfter(minTime) && _selectedDateTime.isBefore(maxTime);
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
            // Thanh kéo nhỏ phía trên
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.withOpacity(0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.green
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? Colors.green : Colors.black54,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          method == PaymentMethod.zenhome
                              ? "${method.label} (Số dư: ${FormatHelper.formatPrice(balance)})"
                              : method.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? ColorConfig.primary
                                : Colors.black87,
                          ),
                        ),
                      ),

                      if (isSelected)
                        Icon(Icons.check_circle, color: ColorConfig.primary),
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

  String _formatWorkingHours(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
  String _getWorkingHoursForOrder() {
    if (_timeType == 'now') {
      // Đặt ngay: thời gian thực hiện là hiện tại + 20 phút (giữ logic cũ)
      final now = DateTime.now().add(const Duration(minutes: 20));
      return _formatWorkingHours(now);
    } else {
      // Đặt trước: dùng thời gian đã chọn
      return _formatWorkingHours(_selectedDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final technician = widget.data['technician'];
    final service = widget.data['timePrice'];
    final workingHours = _formatWorkingHours(_selectedDateTime);
    final totalOrderValue = _totalBeforeDiscount;

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
              "Đặt ngẫu nhiên KTV",
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
              // 🔴 Dòng thông báo tách riêng
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
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // if (_selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 20))))
              // if (_selectedDateTime.isBefore(DateTime.now()))
              //   const Text(
              //     "Thời gian phải sau thời điểm hiện tại ít nhất 20 phút",
              //     style: TextStyle(color: Colors.red, fontSize: 12),
              //   ),

              // Sửa dòng trong bottomNavigationBar
              if (_timeType == 'book' && _selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 60))))
                const Text(
                  "Thời gian đặt trước phải sau ít nhất 60 phút",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),

              // 🧾 Nội dung chính
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Tổng tiền",
                          style: TextStyle(color: Colors.grey),
                        ),
                        if (_discountData != null) ...[
                          // Text(
                          //   "${FormatHelper.formatPrice(_totalBeforeDiscount)} đ",
                          //   style: const TextStyle(
                          //     fontSize: 13,
                          //     color: Colors.grey,
                          //     decoration: TextDecoration.lineThrough,
                          //   ),
                          // ),
                          Text(
                            "${FormatHelper.formatPrice(_finalTotal)} đ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: ColorConfig.textPrimary,
                            ),
                          ),
                        ] else
                          Text(
                            "${FormatHelper.formatPrice(_totalBeforeDiscount)} đ",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 🔵 Nút nạp tiền
                  if (_isInsufficientBalance &&
                      _paymentMethod == PaymentMethod.zenhome)
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

                  // 🟡 Nút đặt
                  // ElevatedButton(
                  //   onPressed: _canSubmit ? _createOrder : null,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor:
                  //     _canSubmit ? ColorConfig.primary : Colors.grey,
                  //     foregroundColor: ColorConfig.textWhite,
                  //   ),
                  //   child: const Text("Đặt ngay"),
                  // ),

                  ElevatedButton(
                    onPressed: (_canSubmit && !_isCreatingOrder) ? _createOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_canSubmit && !_isCreatingOrder) ? ColorConfig.primary : Colors.grey,
                      foregroundColor: ColorConfig.textWhite,
                    ),
                    child: _isCreatingOrder
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text("Đặt ngay"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      body: GestureDetector(
        onTap: () {
          // Tắt bàn phím khi tap ra ngoài
          FocusScope.of(context).unfocus();
        },
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 10, left: 14, right: 14, top: 0),
        child: Column(
          children: [
            // === Thông tin dịch vụ ===
            Section(
              child: Container(
                // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  // border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== HÀNG 1: TÊN DỊCH VỤ =====
                    Text(
                      widget.data['service']['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ===== HÀNG 2: TIME | PRICE =====
                    Row(
                      children: [
                        // TIME
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.data['timePrice']['duration']} phút",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // divider
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),

                        // PRICE
                        Row(
                          children: [
                            const Icon(Icons.local_offer, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "${FormatHelper.formatPrice(widget.data['timePrice']['price'])} đ",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                children: [
                  // 1. Địa chỉ
                  _buildInfoRowWithButton(
                    label: 'Địa chỉ của bạn',
                    value: _addressController.text.isEmpty
                        ? 'Chưa có địa chỉ'
                        : _addressController.text,
                    onTap: _showAddressPicker,
                    buttonLabel:
                    _addressController.text.isEmpty ? 'Chọn' : 'Thay đổi',
                  ),

                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

                  // 2. Thanh toán
                  _buildInfoRowWithButton(
                    label: 'Phương thức thanh toán',
                    value: _paymentMethod?.label ?? 'Chưa chọn',
                    onTap: _openPaymentSelector,
                    buttonLabel:
                    _paymentMethod == null ? 'Chọn' : 'Thay đổi',
                  ),

                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Row(
                  //         children: const [
                  //           SizedBox(width: 6),
                  //           Text(
                  //             "Thời gian thực hiện",
                  //             style: TextStyle(
                  //               fontWeight: FontWeight.bold,
                  //               fontSize: 14,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //       const SizedBox(height: 6),
                  //
                  //       InkWell(
                  //         onTap: _pickDateTime,
                  //         borderRadius: BorderRadius.circular(10),
                  //         child: InputBox(
                  //           child: Row(
                  //             children: [
                  //               const Icon(Icons.calendar_today,
                  //                   color: Colors.grey, size: 20),
                  //               const SizedBox(width: 8),
                  //
                  //               Expanded(
                  //                 child: RichText(
                  //                   text: TextSpan(
                  //                     style: const TextStyle(fontSize: 14, color: Colors.black),
                  //                     children: [
                  //                       TextSpan(
                  //                         text:
                  //                         "${_selectedDateTime.day.toString().padLeft(2, '0')}/"
                  //                             "${_selectedDateTime.month.toString().padLeft(2, '0')}/"
                  //                             "${_selectedDateTime.year}",
                  //                       ),
                  //                       TextSpan(
                  //                         text:
                  //                         " • ${_selectedDateTime.hour.toString().padLeft(2, '0')}:"
                  //                             "${_selectedDateTime.minute.toString().padLeft(2, '0')}",
                  //                         style: const TextStyle(color: Colors.black),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 ),
                  //               ),
                  //
                  //
                  //               const Icon(Icons.arrow_drop_down,
                  //                   color: Colors.grey),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                  //
                  //       if (_selectedDateTime.isBefore(DateTime.now()))
                  //         Padding(
                  //           padding: const EdgeInsets.only(top: 8),
                  //           child: Row(
                  //             children: const [
                  //               Icon(Icons.warning,
                  //                   color: Colors.red, size: 16),
                  //               SizedBox(width: 4),
                  //               Expanded(
                  //                 child: Text(
                  //                   "Thời gian này đã qua, vui lòng chọn thời gian khác",
                  //                   style: TextStyle(
                  //                     color: Colors.red,
                  //                     fontSize: 12,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //     ],
                  //   ),
                  // ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Thời gian thực hiện",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        // Radio button hàng ngang
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Đặt ngay"),
                                value: "now",
                                groupValue: _timeType,
                                onChanged: (value) {
                                  setState(() => _timeType = value!);
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: ColorConfig.primary,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text("Đặt trước"),
                                value: "book",
                                groupValue: _timeType,
                                onChanged: (value) {
                                  setState(() => _timeType = value!);
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: ColorConfig.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Input chọn thời gian chỉ hiển thị khi chọn "Đặt trước"
                        if (_timeType == 'book') ...[
                          InkWell(
                            onTap: _pickDateTime,
                            borderRadius: BorderRadius.circular(10),
                            child: InputBox(
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 14, color: Colors.black),
                                        children: [
                                          TextSpan(
                                            text: "${_selectedDateTime.day.toString().padLeft(2, '0')}/"
                                                "${_selectedDateTime.month.toString().padLeft(2, '0')}/"
                                                "${_selectedDateTime.year}",
                                          ),
                                          TextSpan(
                                            text: " • ${_selectedDateTime.hour.toString().padLeft(2, '0')}:"
                                                "${_selectedDateTime.minute.toString().padLeft(2, '0')}",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          if (!_isValidBookingTime && _timeType == 'book')
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: const [
                                  Icon(Icons.warning, color: Colors.red, size: 16),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Thời gian đặt trước phải sau hiện tại ít nhất 60 phút và không quá 7 ngày",
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ] else ...[
                          // Khi chọn "Đặt ngay", hiển thị thông báo
                          // Container(
                          //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          //   decoration: BoxDecoration(
                          //     color: Colors.grey.shade100,
                          //     borderRadius: BorderRadius.circular(10),
                          //   ),
                          //   child: const Row(
                          //     children: [
                          //       Icon(Icons.access_time, size: 16, color: Colors.grey),
                          //       SizedBox(width: 8),
                          //       Text(
                          //         "Sẽ được thực hiện ngay sau khi đặt hàng thành công",
                          //         style: TextStyle(color: Colors.black87, fontSize: 13),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

                  // 4. Discount
                  _buildDiscountRow(),

                  const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),

                  // 5. Tip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Phí hỗ trợ thêm',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Tooltip(
                              message:
                              'Khoản tiền hỗ trợ thêm cho kỹ thuật viên (không bắt buộc)',
                              child: Icon(Icons.info_outline,
                                  size: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _moneyPrioritizeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nhập số tiền',
                              hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14),
                              isDense: true,
                              contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (_) {
                              setState(() {});
                              if (_appliedDiscountCode != null)
                                _refreshDiscount();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // === Chi tiết thanh toán ===
            Section(
              title: "Chi tiết thanh toán",
              icon: Icons.receipt,
              child: Column(
                children: [
                  InfoRow(
                    "Giá dịch vụ",
                    "${FormatHelper.formatPrice(widget.data['timePrice']['price'])} đ",
                  ),
                  if (_extraFee > 0)
                    InfoRow(
                      "Phí hỗ trợ thêm",
                      "+${FormatHelper.formatPrice(_extraFee)} đ",
                      valueStyle: const TextStyle(color: Colors.green),
                    ),
                  if (_discountData != null)
                    InfoRow(
                      "Giảm giá",
                      "- ${_discountData!['typeDiscount'] == 'percentage' ? '${_discountData!['value']}%' : FormatHelper.formatPrice(_discountData!['value'] as int) + ' đ'}",
                      valueStyle: const TextStyle(color: Colors.red),
                    ),
                  const Divider(height: 20),
                  InfoRow(
                    "Tổng cộng",
                    "${FormatHelper.formatPrice(_finalTotal)} đ",
                    valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Section(
              title: "Ghi chú",
              // icon: Icons.note,
              child: InputBox(
                isFocused: _noteFocusNode.hasFocus,
                child: TextField(
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () {
                    _noteFocusNode.unfocus();
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Ví dụ: thời gian phù hợp, tình trạng cụ thể, lưu ý khi đến…",
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
      )
    );
  }
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

            // const SizedBox(height: 6),

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
}
