import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/routes/config/customer_router_config.dart';
import 'package:spa_app/services/user_discount_service.dart';

import '../../../helper/format_helper.dart';
import '../../../helper/logger_utils.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/discount_service.dart';
import '../../../storage/index.dart';

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

  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 20));

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
      firstDate: DateTime.now().add(const Duration(minutes: 20)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.amber),
          ),
          child: child!,
        );
      },
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 20))),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.amber),
          ),
          child: child!,
        );
      },
    );

    if (time == null) return;

    final selectedDateTime = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );

    if (selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 20)))) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Thời gian không hợp lệ"),
            content: const Text("Thời gian đặt lịch phải sau thời điểm hiện tại ít nhất 20 phút và không quá 7 ngày."),
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

  // Mở bottom sheet chọn địa chỉ
  void _showAddressPicker() {
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
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chọn địa chỉ',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  Expanded(
                    child: (_addresses.isEmpty)
                        ? const Center(
                      child: Text('Chưa có địa chỉ nào'),
                    )
                        : ListView.builder(
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final addr = _addresses[index];
                        final isDefault = addr['isDefault'] == true;

                        return ListTile(
                          leading: Icon(isDefault
                              ? Icons.home
                              : Icons.location_on),
                          title: Text(addr['address']),
                          trailing: _addressController.text ==
                              addr['address']
                              ? const Icon(Icons.check_circle,
                              color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _addressController.text =
                              addr['address'];
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push(CustomerRouterConfig.addAddress);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm địa chỉ'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
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

  // Mở bottom sheet nhập mã giảm giá
  void _showDiscountBottomSheet() {
    final TextEditingController couponController = TextEditingController();
    couponController.text = _appliedDiscountCode ?? '';

    String? localError;
    bool localChecking = false;
    String? selectedDiscountId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 🔥 QUAN TRỌNG để set height
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

                    const SizedBox(height: 16),

                    /// 🔥 INPUT + BUTTON CÙNG HÀNG
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            textCapitalization:
                            TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Mã giảm giá',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
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
                          final value = discount['value'];
                          final minOrder = discount['minOrderValue'];

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
                                      'Giảm: ${value.toString()}đ'),
                                  Text(
                                      'Đơn tối thiểu: ${minOrder.toString()}đ'),
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
        !_isInsufficientBalance; // Thêm điều kiện kiểm tra số dư
  }

  void _openPaymentSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: PaymentMethod.values.map((method) {
          return ListTile(
            leading: const Icon(Icons.payment),
            title: Text(method.label),
            trailing: _paymentMethod == method
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              setState(() => _paymentMethod = method);
              Navigator.pop(context);
            },
          );
        }).toList(),
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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Xác nhận đặt lịch",
          style: TextStyle(fontWeight: FontWeight.w600),
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

              if (_selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 20))))
                const Text(
                  "Thời gian phải sau thời điểm hiện tại ít nhất 20 phút",
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

                  // 🟡 Nút đặt
                  ElevatedButton(
                    onPressed: _canSubmit ? _createOrder : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      _canSubmit ? Colors.amber : Colors.grey,
                      foregroundColor: Colors.black,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // === Thông tin kỹ thuật viên & dịch vụ ===
            _Section(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(
                            FormatHelper.formatNetworkImageUrl(technician['avatar']['url'])),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FormatHelper.formatNameTechnician(technician['fullName']),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text("⭐ ${technician['rate']}"),
                          ],
                        ),
                      ),
                      const Icon(Icons.spa, color: Colors.grey),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    "Dịch vụ",
                    widget.data['nameService'],
                    valueStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _InfoRow("Thời gian", "${service['duration']} phút"),
                  _InfoRow("Giá", "${FormatHelper.formatPrice(widget.data['serviceTimePrice']['price'])} đ"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // === Thời gian thực hiện ===
            _Section(
              title: "Thời gian thực hiện",
              icon: Icons.access_time,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _pickDateTime,
                    child: _InputBox(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${_selectedDateTime.day.toString().padLeft(2, '0')}/${_selectedDateTime.month.toString().padLeft(2, '0')}/${_selectedDateTime.year}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  "${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedDateTime.isBefore(DateTime.now().add(const Duration(minutes: 20))))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: const [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Thời gian này đã qua, vui lòng chọn thời gian khác",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            // === Địa chỉ (click mở bottom sheet) ===
            _Section(
              title: "Địa chỉ của tôi",
              icon: Icons.location_on_outlined,
              child: InkWell(
                onTap: _showAddressPicker,
                child: _InputBox(
                  text: _addressController.text.isEmpty
                      ? "Chọn địa chỉ"
                      : _addressController.text,
                  isPlaceholder: _addressController.text.isEmpty,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // === Phương thức thanh toán ===
            _Section(
              title: "Phương thức thanh toán",
              icon: Icons.payment,
              child: Column(
                children: [
                  InkWell(
                    onTap: _openPaymentSelector,
                    child: _InputBox(
                      text: _paymentMethod?.label ?? "Chọn phương thức thanh toán",
                      isPlaceholder: _paymentMethod == null,
                    ),
                  ),
                  if (_paymentMethod == PaymentMethod.zenhome) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Số dư ví: ${FormatHelper.formatPrice(balance)} đ',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push(CustomerRouterConfig.choosePackage);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.amber,
                            ),
                            child: const Text('Nạp tiền'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // === Mã giảm giá (click mở bottom sheet) ===
            _Section(
              title: "Mã giảm giá",
              icon: Icons.confirmation_number_outlined,
              child: InkWell(
                onTap: _showDiscountBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _discountData != null
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mã: ${_appliedDiscountCode}',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Giảm ${_discountData!['typeDiscount'] == 'percentage' ? '${_discountData!['value']}%' : '${FormatHelper.formatPrice(_discountData!['value'] as int)} đ'}',
                              style: const TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        )
                            : const Text(
                          'Nhấn để chọn mã giảm giá',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      if (_discountData != null)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: _removeDiscount,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      else
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // === Ghi chú ===
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
            _Section(
              title: "Phí hỗ trợ thêm",
              icon: Icons.payments_outlined,
              child: _InputBox(
                child: TextField(
                  controller: _moneyPrioritizeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onEditingComplete: () {
                    // Format lại khi kết thúc nhập
                    int value = _extraFee;
                    if (value > 0) {
                      _moneyPrioritizeController.text = FormatHelper.formatPrice(value).replaceAll(' đ', '');
                      setState(() {});
                      if (_appliedDiscountCode != null) _refreshDiscount();
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Khoản hỗ trợ thêm (không bắt buộc)",
                  ),
                  onChanged: (_) {
                    setState(() {});
                    if (_appliedDiscountCode != null) {
                      _refreshDiscount();
                    }
                  },
                ),
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
            const SizedBox(height: 90),
          ],
        ),
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
          color: isFocused ? Colors.amber : Colors.transparent,
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