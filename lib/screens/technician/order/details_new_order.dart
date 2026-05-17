import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/snackbar_helper.dart';
import 'package:spa_app/services/order_service.dart';
import '../../../helper/format_helper.dart';
import 'dart:async';

import '../../../storage/index.dart';

class DetailsNewOrderScreen extends StatefulWidget {
  final String orderId;
  const DetailsNewOrderScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<DetailsNewOrderScreen> createState() => _DetailsNewOrderScreenState();
}

class _DetailsNewOrderScreenState extends State<DetailsNewOrderScreen> {
  final OrderService _orderService = OrderService();
  Map<String, dynamic>? orderDetail;
  bool isLoading = true;

  Timer? _timer;
  Duration _remainingTime = const Duration(minutes: 5);
  bool _isExpired = false;

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDetailOrder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noteController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> loadDetailOrder() async {
    try {
      final response = await _orderService.detailOrder(widget.orderId);
      appLog('Chi tiết đơn mới: $response');
      if (response['success'] == true) {
        setState(() {
          orderDetail = response['data'];
          isLoading = false;
        });
        _startCountdown();
      }
    } catch (e) {
      debugPrint('Error loading detail order: $e');
      setState(() => isLoading = false);
    }
  }

  void _startCountdown() {
    final createdAtStr = orderDetail!['createdAt'] as String?;
    if (createdAtStr == null) {
      setState(() => _isExpired = true);
      return;
    }

    final createdAt = DateTime.parse(createdAtStr).toLocal();
    final deadline = createdAt.add(const Duration(minutes: 5));
    final now = DateTime.now();

    if (now.isAfter(deadline)) {
      setState(() => _isExpired = true);
      return;
    }

    _remainingTime = deadline.difference(now);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        setState(() => _isExpired = true);
      } else {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> acceptOrder() async {
    final note = _noteController.text.trim();
    try {
      final data = {
        'orderId': widget.orderId,
        'result': 'approved',
        'noteTechnician': note,
      };
      final response = await _orderService.updateStatus(data);
      appLog('response : $response');

      if (response['success'] == true) {
        setState(() => isLoading = false);
        if (!mounted) return;

        final acceptedAt = DateTime.now().toIso8601String();

        await SharedPrefs.saveValue(PrefType.string, "orderDetail", orderDetail);
        await SharedPrefs.saveValue(PrefType.bool, "isWorking", true);
        await SharedPrefs.saveValue(PrefType.string, "idOrderWorking", widget.orderId);

        // 👇 thêm dòng này
        await SharedPrefs.saveValue(PrefType.string, "acceptedAt", acceptedAt);

        SnackBarHelper.showSuccess(context, "Chấp nhận đơn thành công!");
        context.go('/home-technician');
      }

    } catch (e) {
      debugPrint('Error accepting order: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> rejectOrder() async {
    _rejectReasonController.clear();
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Lý do từ chối', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: TextField(
            controller: _rejectReasonController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Vui lòng nhập lý do từ chối...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ColorConfig.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                final text = _rejectReasonController.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do từ chối')),
                  );
                  return;
                }
                Navigator.pop(context, text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      try {
        final data = {
          'orderId': widget.orderId,
          'result': 'reject',
          'noteTechnician': '',
          'reasonReject': reason,
        };
        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          setState(() => isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã từ chối đơn hàng')),
          );
          context.go('/home-technician');
        }
      } catch (e) {
        debugPrint('Error rejecting order: $e');
        setState(() => isLoading = false);
      }
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionGap() => const SizedBox(height: 8);

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: ColorConfig.textBlack,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: valueColor ?? Colors.black87,
                        height: 1.4,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey[100]),
          ),
      ],
    );
  }

  Widget _priceRow({
    required String label,
    required String value,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isTotal ? ColorConfig.primary : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (orderDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 52, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('Không tìm thấy đơn', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    final status = orderDetail!['status'] as String? ?? '';
    final isPending = status == 'pending';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
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
                    color: Colors.white,
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
            const SizedBox(width: 6),

            Expanded(
              child: Text(
                "Chi tiết đơn việc",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
            ),

          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        children: [
          ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Dịch vụ'),
                _infoRow(
                  icon: Icons.spa_outlined,
                  label: 'Tên dịch vụ',
                  value: orderDetail!['nameService'] ?? 'Chưa có thông tin',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                _priceRow(
                  label: 'Thời gian',
                  value: '${orderDetail!['serviceTimePrice']['duration'] ?? 60} phút',
                ),
                _priceRow(
                  label: 'Giá dịch vụ',
                  value: '${FormatHelper.formatPrice(orderDetail!['price'])} ₫',
                ),
                if (orderDetail!['isPrioritize'] == true) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(height: 1, thickness: 0.5, color: Colors.grey[100]),
                  ),
                  _priceRow(
                    label: 'Phí hỗ trợ',
                    value: '+${FormatHelper.formatPrice(orderDetail!['moneyPrioritize'])} ₫',
                    valueColor: ColorConfig.textPrimary,
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
                ),
                // _priceRow(
                //   label: 'Tổng thanh toán',
                //   value: '${FormatHelper.formatPrice(orderDetail!['deposit'])} ₫',
                //   isTotal: true,
                // ),
                // const SizedBox(height: 6),
              ],
            ),
          ),

          _sectionGap(),

          // ── Khách hàng ────────────────────────────────────────────────────
          ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Khách hàng'),
                _infoRow(
                  icon: Icons.person_outline,
                  label: 'Họ tên',
                  value: orderDetail!['customer']?['fullname'] ?? 'Chưa có thông tin',
                ),
                _infoRow(
                  icon: Icons.wc_outlined,
                  label: 'Giới tính',
                  value: FormatHelper.formatGender(orderDetail!['customer']?['gender'] ?? ''),
                ),
                // _infoRow(
                //   icon: Icons.phone_outlined,
                //   label: 'Số điện thoại',
                //   value: orderDetail!['customer']?['phone'] ?? 'Chưa có thông tin',
                // ),
                _infoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Địa chỉ',
                  value: orderDetail!['address'] ?? 'Chưa có thông tin',
                  isLast: true,
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          _sectionGap(),

          // ── Ghi chú khách ─────────────────────────────────────────────────
          ColoredBox(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Ghi chú khách'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text(
                    orderDetail!['noteCustomer']?.isNotEmpty == true
                        ? orderDetail!['noteCustomer']
                        : 'Không có ghi chú',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: orderDetail!['noteCustomer']?.isNotEmpty == true
                          ? Colors.black87
                          : Colors.grey[400],
                    ),
                  ),
                ),
                if (orderDetail!['reasonReject']?.isNotEmpty == true) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 15, color: Colors.red.shade400),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Lý do từ chối',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  orderDetail!['reasonReject'],
                                  style: TextStyle(fontSize: 14, color: Colors.red.shade800, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          _sectionGap(),

          // ── Khu vực hành động ─────────────────────────────────────────────
          if (isPending && !_isExpired) ...[
            ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 15, color: Colors.orange.shade600),
                          const SizedBox(width: 7),
                          Text(
                            'Còn ${_formatDuration(_remainingTime)} để phản hồi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú kỹ thuật viên
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ghi chú gửi khách (không bắt buộc)...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: ColorConfig.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nút hành động
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: rejectOrder,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                            ),
                            child: Text(
                              'Từ chối',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: acceptOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConfig.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Chấp nhận',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Trạng thái đã xử lý hoặc hết hạn
            ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      _isExpired ? Icons.timer_off_outlined : Icons.info_outline,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isExpired
                            ? 'Đơn đã hết thời gian xử lý (5 phút)'
                            : (status == 'rejected' ? 'Đơn đã bị từ chối' : 'Đơn đã được chấp nhận'),
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}