import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/format_helper.dart';
import '../../helper/logger_utils.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/discount_service.dart';

enum PaymentMethod { cash, momo, bank }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tiền mặt';
      case PaymentMethod.momo:
        return 'Ví MoMo';
      case PaymentMethod.bank:
        return 'Chuyển khoản';
    }
  }
}

class CreateOrderTechnicianScreen extends StatefulWidget {
  final dynamic data;

  const CreateOrderTechnicianScreen({
    super.key,
    required this.data,
  });

  @override
  State<CreateOrderTechnicianScreen> createState() =>
      _CreateOrderTechnicianScreenState();
}

class _CreateOrderTechnicianScreenState
    extends State<CreateOrderTechnicianScreen> {
  final OrderService _orderService = OrderService();
  final DiscountService _discountService = DiscountService();
  bool _loading = true;

  final _addressController = TextEditingController();
  final _couponController = TextEditingController();
  final _noteController = TextEditingController();

  PaymentMethod? _paymentMethod;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 30));

  // Focus nodes for input fields
  final _addressFocusNode = FocusNode();
  final _couponFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();

  // ===== DISCOUNT STATE =====
  Map<String, dynamic>? _discountData; // data trả về khi mã hợp lệ
  String? _discountError;              // thông báo lỗi khi mã không hợp lệ
  bool _isCheckingCoupon = false;      // loading khi đang kiểm tra mã

  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
    appLog("CreateOrderTechnicianScreen data", data: widget.data);

    _addressFocusNode.addListener(_onFocusChange);
    _couponFocusNode.addListener(_onFocusChange);
    _noteFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _couponController.dispose();
    _noteController.dispose();
    _addressFocusNode.dispose();
    _couponFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadCustomerProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawProfile = prefs.getString('customerProfile');
      if (rawProfile != null) {
        final profile = jsonDecode(rawProfile);
        _addressController.text = profile['address'] ?? '';
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Nếu người dùng đã nhập mã thì mã PHẢI hợp lệ mới cho đặt.
  // Nếu ô mã trống thì bỏ qua điều kiện mã giảm giá.
  bool get _canSubmit {
    final hasCoupon = _couponController.text.trim().isNotEmpty;
    final couponValid = _discountData != null;
    return _addressController.text.trim().isNotEmpty &&
        _paymentMethod != null &&
        !_isPastTime(_selectedDateTime) &&
        (!hasCoupon || couponValid);
  }

  bool _isPastTime(DateTime selectedTime) {
    return selectedTime.isBefore(DateTime.now());
  }

  // ===== ÁP DỤNG MÃ GIẢM GIÁ =====
  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountData = null;
        _discountError = "Vui lòng nhập mã giảm giá";
      });
      return;
    }

    final service = widget.data['serviceTimePrice'];
    final price = service['price'] as int;

    setState(() {
      _isCheckingCoupon = true;
      _discountError = null;
      _discountData = null;
    });

    try {
      final response = await _discountService.checkDiscountService({
        "code": code,
        "orderValue": price,
      });

      if (response['success'] == true) {
        setState(() {
          _discountData = response['data'];
          _discountError = null;
        });
      } else {
        setState(() {
          _discountData = null;
          _discountError = response['message'] ?? 'Mã giảm giá không hợp lệ';
        });
      }
    } catch (e) {
      appLog("Lỗi kiểm tra mã giảm giá: ", data: e);
      setState(() {
        _discountData = null;
        _discountError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
      });
    } finally {
      if (mounted) setState(() => _isCheckingCoupon = false);
    }
  }

  // Reset discount khi người dùng thay đổi nội dung ô mã
  void _onCouponChanged(String value) {
    final upper = value.toUpperCase();
    if (value != upper) {
      _couponController.value = _couponController.value.copyWith(
        text: upper,
        selection: TextSelection.collapsed(offset: upper.length),
      );
    }
    // Xoá kết quả cũ mỗi khi người dùng chỉnh sửa mã
    setState(() {
      _discountData = null;
      _discountError = null;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      initialTime: TimeOfDay.now(),
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

    if (selectedDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Thời gian không hợp lệ"),
            content: const Text(
                "Bạn không thể chọn thời gian ở quá khứ. Vui lòng chọn thời gian khác."),
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
    final price = service['price'] as int;
    final workingHours = _formatWorkingHours(_selectedDateTime);

    // Tính giá sau giảm để hiển thị
    final discountedPrice = _discountData != null
        ? (_discountData!['orderValueAfterDiscount'] as int)
        : price;

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

      // ================= BOTTOM BAR =================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Tổng tiền", style: TextStyle(color: Colors.grey)),
                    // Nếu có giảm giá, gạch giá gốc và hiển thị giá mới
                    if (_discountData != null) ...[
                      Text(
                        "${FormatHelper.formatPrice(price)} đ",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        "${FormatHelper.formatPrice(discountedPrice)} đ",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ] else
                      Text(
                        "${FormatHelper.formatPrice(price)} đ",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    if (_isPastTime(_selectedDateTime))
                      const Text(
                        "Thời gian đã chọn là quá khứ",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _canSubmit
                    ? () async {
                  final data = {
                    "technicianId": widget.data['technician']['id'],
                    "serviceTimePriceId": widget.data['serviceTimePrice']['_id'],
                    "nameService": widget.data['nameService'],
                    "address": _addressController.text.trim(),
                    "paymentMethod": _paymentMethod!.name,
                    "coupon": _couponController.text.trim(),
                    "time": _selectedDateTime.toIso8601String(),
                    "price": price,
                    "noteCustomer": _noteController.text.trim(),
                    'workingHours': workingHours,
                    // Chỉ gửi discount nếu mã hợp lệ
                    if (_discountData != null)
                      'discount': {
                        "discountId": _discountData!['discountId'],
                        "code": _discountData!['code'],
                        "typeDiscount": _discountData!['typeDiscount'],
                        "value": _discountData!['value'],
                        "amountDiscount": _discountData!['amountDiscount'],
                      },
                  };

                  try {
                    final response = await _orderService.createOrrder(data);
                    if (response['success'] == true) {
                      context.go('/home-customer');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Tạo đơn thành công! Vui lòng chờ kỹ thuật viên phản hồi!",
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else {
                      throw Exception(response['message'] ??
                          'Không thể tạo đơn hàng');
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
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSubmit ? Colors.amber : Colors.grey,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Đặt ngay"),
              ),
            ],
          ),
        ),
      ),

      // ================= BODY =================
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== TECH + SERVICE =====
            _Section(
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundImage:
                        NetworkImage(FormatHelper.formatNetworkImageUrl(technician['avatar']['url'])),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FormatHelper.formatNameTechnician(technician['fullName']),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
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
                  _InfoRow(
                      "Giá", "${FormatHelper.formatPrice(price)} đ"),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== TIME =====
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
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
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
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  if (_isPastTime(_selectedDateTime))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: const [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Thời gian này đã qua, vui lòng chọn thời gian khác",
                            style: TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== ADDRESS =====
            _Section(
              title: "Địa chỉ của tôi",
              icon: Icons.location_on_outlined,
              child: _InputBox(
                isFocused: _addressFocusNode.hasFocus,
                child: TextField(
                  controller: _addressController,
                  focusNode: _addressFocusNode,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Nhập địa chỉ của bạn",
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== PAYMENT =====
            _Section(
              title: "Phương thức thanh toán",
              icon: Icons.payment,
              child: InkWell(
                onTap: _openPaymentSelector,
                child: _InputBox(
                  text: _paymentMethod?.label ??
                      "Chọn phương thức thanh toán",
                  isPlaceholder: _paymentMethod == null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== COUPON =====
            _Section(
              title: "Mã giảm giá",
              icon: Icons.confirmation_number_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _couponController,
                          focusNode: _couponFocusNode,
                          textCapitalization:
                          TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: "Nhập mã giảm giá",
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            // Border xanh khi hợp lệ, đỏ khi lỗi, vàng khi focus
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _discountData != null
                                    ? Colors.green
                                    : _discountError != null
                                    ? Colors.red
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _discountData != null
                                    ? Colors.green
                                    : _discountError != null
                                    ? Colors.red
                                    : Colors.amber,
                                width: 1.5,
                              ),
                            ),
                            // Icon trạng thái bên phải
                            suffixIcon: _discountData != null
                                ? const Icon(Icons.check_circle,
                                color: Colors.green)
                                : _discountError != null
                                ? const Icon(Icons.cancel,
                                color: Colors.red)
                                : null,
                          ),
                          onChanged: _onCouponChanged,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút áp dụng / loading
                      SizedBox(
                        width: 90,
                        child: _isCheckingCoupon
                            ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber,
                            ),
                          ),
                        )
                            : TextButton(
                          onPressed: _applyCoupon,
                          child: const Text("Áp dụng"),
                        ),
                      ),
                    ],
                  ),

                  // Thông báo lỗi mã giảm giá
                  if (_discountError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _discountError!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Thông báo thành công + chi tiết giảm giá
                  if (_discountData != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_offer,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Giảm ${_discountData!['typeDiscount'] == 'percentage' ? '${_discountData!['value']}%' : '${FormatHelper.formatPrice(_discountData!['value'] as int)} đ'} "
                                    "— tiết kiệm ${FormatHelper.formatPrice(_discountData!['amountDiscount'] as int)} đ",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== NOTE =====
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
                    hintText:
                    "Nhập ghi chú của bạn cho kỹ thuật viên",
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
}

// ================= UI COMPONENTS =================
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