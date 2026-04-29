import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
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

class CreateBookOrderScreen extends StatefulWidget {
  final dynamic data;

  const CreateBookOrderScreen({
    super.key,
    required this.data,
  });

  @override
  State<CreateBookOrderScreen> createState() =>
      _CreateBookOrderScreenState();
}

class _CreateBookOrderScreenState
    extends State<CreateBookOrderScreen> {
  final OrderService _orderService = OrderService();
  final DiscountService _discountService = DiscountService();
  final UserDiscountService _userDiscountService = UserDiscountService();

  bool _loading = true;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRefreshingDiscount = false;

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

  // Thanh toán
  PaymentMethod? _paymentMethod;

  int balance = 0;

  @override
  void initState() {
    super.initState();
    _paymentMethod = PaymentMethod.zenhome;
    _loadCustomerProfile();
    _loadSavedDiscounts();
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

  int get _totalBeforeDiscount => (widget.data['serviceTimePrice']['price'] as int) + _extraFee;

  int get _finalTotal {
    if (_discountData != null) {
      final amountDiscount = _discountData!['amountDiscount'] as int;
      return _totalBeforeDiscount - amountDiscount;
    }
    return _totalBeforeDiscount;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().add(const Duration(minutes: 62)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
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

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 62))),
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

    if (selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 60)))) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Thời gian không hợp lệ"),
            content: const Text("Thời gian đặt lịch phải sau thời điểm hiện tại ít nhất 60 phút và không quá 7 ngày."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _selectedDateTime = selectedDateTime);
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

  Future<void> _createOrder() async {
    final moneyPrioritizeRaw = _moneyPrioritizeController.text.trim();
    final moneyPrioritize = moneyPrioritizeRaw.isEmpty ? 0 : int.tryParse(moneyPrioritizeRaw) ?? 0;
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
      'workingHours': _formatWorkingHours(_selectedDateTime),

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
    }
  }

  Future<void> _loadCustomerProfile() async {
    try {
      balance = await SharedPrefs.getValue(PrefType.int, "balance") ?? 0;
      final rawProfile = await SharedPrefs.getValue(PrefType.string, "customerProfile");
      appLog("data Profile: $rawProfile");
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
        appLog("list discount: $_discounts");
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

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.7;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: height,
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

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Chọn địa chỉ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔥 LIST ĐỊA CHỈ
                  Expanded(
                    child: (_addresses.isEmpty)
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
                        final isSelected =
                            _addressController.text == addr['address'];

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
                            onTap: () {
                              setState(() {
                                _addressController.text =
                                addr['address'];
                              });
                              Navigator.pop(context);
                            },
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

                                /// TEXT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        addr['address'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isDefault)
                                        Padding(
                                          padding:
                                          EdgeInsets.only(top: 4),
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

                                /// CHECK
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

                  /// 👇 BUTTON
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push(CustomerRouterConfig.addAddress);
                        },
                        icon: Icon(Icons.add, color: ColorConfig.white,),
                        label: Text('Thêm địa chỉ mới', style: TextStyle(color: ColorConfig.textWhite),),
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
          },
        );
      },
    );
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
                            style: const TextStyle(
                              fontSize: 14,
                            ),
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
                            final code = couponController.text
                                .trim()
                                .toUpperCase();

                            if (code.isEmpty) {
                              setSheetState(() =>
                              localError = 'Vui lòng nhập mã');
                              return;
                            }

                            setSheetState(() {
                              localChecking = true;
                              localError = null;
                            });

                            final price = (widget.data[
                            'serviceTimePrice']['price'] as int);

                            try {
                              final response =
                              await _discountService
                                  .checkDiscountService({
                                "code": code,
                                "orderValue": price,
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
                                  localError = response['message'] ??
                                      'Mã không hợp lệ';
                                  localChecking = false;
                                });
                              }
                            } catch (e) {
                              appLog("Lỗi kiểm tra mã: ", data: e);
                              setSheetState(() {
                                localError =
                                'Không thể kiểm tra mã';
                                localChecking = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.primary,
                            foregroundColor: ColorConfig.textWhite,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                          ),
                          child: localChecking
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Áp dụng'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔥 LIST DISCOUNT
                    const Text(
                      'Mã của bạn',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: (_discounts == null || _discounts.isEmpty)
                          ? const Center(
                        child: Text('Không có mã giảm giá'),
                      )
                          : ListView.builder(
                        itemCount: _discounts.length,
                        itemBuilder: (context, index) {
                          final item = _discounts[index];
                          final discount = item['discount'];

                          final code = discount['code'];
                          final int value = discount['value'];
                          final int minOrder = discount['minOrderValue'];

                          final isSelected =
                              selectedDiscountId == item['id'];

                          return GestureDetector(
                            onTap: () {
                              setSheetState(() {
                                selectedDiscountId = item['id'];
                                couponController.text = code;
                              });
                            },
                            child: Container(
                              margin:
                              const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Giảm: ${FormatHelper.formatPrice(value)} đ'),
                                  Text(
                                      'Đơn tối thiểu: ${FormatHelper.formatPrice(minOrder)} đ'),
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

  bool get _canSubmit {
    final hasCoupon = _appliedDiscountCode != null && _appliedDiscountCode!.isNotEmpty;
    final couponValid = _discountData != null;
    return _addressController.text.trim().isNotEmpty &&
        _paymentMethod != null &&
        (!hasCoupon || couponValid) &&
        !_isInsufficientBalance;
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

  @override
  Widget build(BuildContext context) {
    final technician = widget.data['technician'];
    final service = widget.data['serviceTimePrice'];
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
              "Xác nhận đặt lịch trước",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: ColorConfig.black),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
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
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              if (_selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 60))))
                const Text(
                  "Thời gian phải sau thời điểm hiện tại ít nhất 60 phút",
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
                          Text(
                            "${FormatHelper.formatPrice(_totalBeforeDiscount)} đ",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            "${FormatHelper.formatPrice(_finalTotal)} đ",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Nạp tiền"),
                      ),
                    ),

                  ElevatedButton(
                    onPressed: _canSubmit ? _createOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _canSubmit ? ColorConfig.primary : Colors.grey,
                      foregroundColor: Colors.black,
                    ),
                    child: Text("Đặt ngay", style: TextStyle(color: ColorConfig.textWhite),),
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
        padding: const EdgeInsets.only(top: 0, right: 14, left: 14, bottom: 10),
        child: Column(
          children: [
            // === Thông tin kỹ thuật viên & dịch vụ ===
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== SERVICE =====
                  Text(
                    widget.data['nameService'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: ColorConfig.textBlack.withOpacity(.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${service['duration']} phút",
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorConfig.textBlack.withOpacity(.5),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        width: 1,
                        height: 12,
                        color: Colors.black.withOpacity(.08),
                      ),

                      const SizedBox(width: 10),

                      Icon(
                        Icons.local_offer_outlined,
                        size: 14,
                        color: ColorConfig.textBlack.withOpacity(.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${FormatHelper.formatPrice(widget.data['serviceTimePrice']['price'])} đ",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ColorConfig.textBlack.withOpacity(.6),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // divider mềm
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== TECHNICIAN =====
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(.08),
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(
                            FormatHelper.formatNetworkImageUrl(
                              technician['avatar']['url'],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FormatHelper.formatNameTechnician(
                                technician['fullName'],
                              ),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${technician['rate']}",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ColorConfig.textBlack.withOpacity(.6),
                                  ),
                                ),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            SizedBox(width: 6),
                            Text(
                              "Thời gian thực hiện",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        InkWell(
                          onTap: _pickDateTime,
                          borderRadius: BorderRadius.circular(10),
                          child: _InputBox(
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),

                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text:
                                          "${_selectedDateTime.day.toString().padLeft(2, '0')}/"
                                              "${_selectedDateTime.month.toString().padLeft(2, '0')}/"
                                              "${_selectedDateTime.year}",
                                        ),
                                        TextSpan(
                                          text:
                                          " • ${_selectedDateTime.hour.toString().padLeft(2, '0')}:"
                                              "${_selectedDateTime.minute.toString().padLeft(2, '0')}",
                                          style: const TextStyle(color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),


                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        if (_selectedDateTime.isBefore(DateTime.now()))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: const [
                                Icon(Icons.warning,
                                    color: Colors.red, size: 16),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Thời gian này đã qua, vui lòng chọn thời gian khác",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
            const SizedBox(height: 20),
            // === Chi tiết thanh toán ===
            _Section(
              title: "Chi tiết thanh toán",
              icon: Icons.receipt,
              child: Column(
                children: [
                  _InfoRow(
                    "Giá dịch vụ",
                    "${FormatHelper.formatPrice(widget.data['serviceTimePrice']['price'])} đ",
                  ),
                  if (_extraFee > 0)
                    _InfoRow(
                      "Phí hỗ trợ thêm",
                      "+${FormatHelper.formatPrice(_extraFee)} đ",
                      valueStyle: const TextStyle(color: Colors.green),
                    ),
                  if (_discountData != null)
                    _InfoRow(
                      "Giảm giá",
                      "- ${_discountData!['typeDiscount'] == 'percentage' ? '${_discountData!['value']}%' : FormatHelper.formatPrice(_discountData!['value'] as int) + ' đ'}",
                      valueStyle: const TextStyle(color: Colors.red),
                    ),
                  const Divider(height: 20),
                  _InfoRow(
                    "Tổng cộng",
                    "${FormatHelper.formatPrice(_finalTotal)} đ",
                    valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section(
              title: "Ghi chú",
              icon: Icons.note,
              child: _InputBox(
                isFocused: _noteFocusNode.hasFocus,
                child: TextField(
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  maxLines: 2,
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

// ================= UI COMPONENTS (giữ nguyên) =================
class _Section extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget child;

  const _Section({this.title, this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                if (icon != null) Icon(icon, size: 18, color: Colors.grey),
                if (icon != null) const SizedBox(width: 6),
                Text(title!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          if (title != null) const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final String? text;
  final bool isPlaceholder;
  final Widget? child;
  final bool isFocused;

  const _InputBox({
    this.text,
    this.isPlaceholder = false,
    this.child,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? ColorConfig.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: child ??
                Text(
                  text ?? '',
                  style: TextStyle(
                    color: isPlaceholder ? Colors.grey : Colors.black,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow(this.label, this.value, {this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: valueStyle ??
                  const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}