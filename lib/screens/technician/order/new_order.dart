import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/order_service.dart';
import '../../helper/format_helper.dart';
import 'dart:async';

class NewOrderScreen extends StatefulWidget {
  final String orderId;
  const NewOrderScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
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
      _isExpired = true;
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
    // TODO: Gọi API accept với note (nếu có)
    try {
      var data = {
        'orderId': widget.orderId,
        'result': 'accept',
        'noteTechnician': note,
      };
      final response = await _orderService.updateStatus(data);
      if (response['success'] == true) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chấp nhận đơn thành công!')),
        );
        context.go("/home-technician");

      }
    } catch (e) {
      debugPrint('Error loading detail order: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> rejectOrder() async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lý do từ chối đơn'),
          content: TextField(
            controller: _rejectReasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Vui lòng nhập lý do từ chối...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
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
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      // TODO: Gọi API reject với reason
      debugPrint("Reject order ${widget.orderId} with reason: $reason");
      // _rejectReasonController.clear();
      try {
        var data = {
          'orderId': widget.orderId,
          'result': 'reject',
          'noteTechnician': '',
          'reasonReject': reason,
        };
        final response = await _orderService.updateStatus(data);
        if (response['success'] == true) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('')),
          );

          context.go("/home-technician");
        }
      } catch (e) {
        debugPrint('Error loading detail order: $e');
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildInfoItem(String label, String value, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: Colors.blue,
                ),
              ),
            SizedBox(width: icon != null ? 12 : 0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải thông tin...',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (orderDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết đơn')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy đơn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final status = orderDetail!['status'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      body: Container(
        color: const Color(0xFFF8F9FA),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông tin dịch vụ
              _buildSectionTitle('Thông tin dịch vụ'),
              _buildInfoItem(
                'Dịch vụ',
                orderDetail!['nameService'] ?? 'Chưa có thông tin',
                icon: Icons.spa_rounded,
              ),
              _buildInfoItem(
                'Giá',
                '${FormatHelper.formatPrice(orderDetail!['price'])} đ',
                icon: Icons.monetization_on_outlined,
              ),
              _buildInfoItem(
                'Thời gian',
                orderDetail!['workingHours'] ?? '',
                icon: Icons.timelapse,
              ),
              const SizedBox(height: 10),

              // Thông tin khách hàng
              _buildSectionTitle('Thông tin khách hàng'),

              _buildInfoItem('Khách hàng',
                orderDetail!['customer']?['fullname'] ?? 'Chưa có thông tin',
                icon: Icons.person_outline,
              ),

              _buildInfoItem('Giới tính',
                FormatHelper.formatGender(orderDetail!['customer']?['gender'] ?? ''),
                icon: Icons.transgender,
              ),

              _buildInfoItem(
                'Địa chỉ',
                orderDetail!['address'] ?? 'Chưa có thông tin',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 10),

              // Ghi chú khách hàng
              _buildSectionTitle('Ghi chú'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note_outlined, size: 20, color: Colors.amber[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghi chú từ khách hàng',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            orderDetail!['noteCustomer']?.isNotEmpty == true
                                ? orderDetail!['noteCustomer']
                                : 'Không có ghi chú',
                            style: const TextStyle(fontSize: 15, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Chỉ hiển thị khi đang pending và chưa hết hạn
              if (status == 'pending' && !_isExpired)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Thời gian xử lý còn lại: ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _formatDuration(_remainingTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Xử lý đơn',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // Ô nhập ghi chú từ kỹ thuật viên
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Ghi chú gửi khách (vd: tắc đường, đến muộn chút nhé chị)...',
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: rejectOrder,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Từ chối',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: acceptOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Chấp nhận',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vui lòng xử lý đơn trong thời gian sớm nhất',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Nếu hết hạn hoặc không phải pending
              if ((status == 'pending' && _isExpired) || status != 'pending')
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isExpired
                          ? 'Đơn đã hết thời gian xử lý (5 phút)'
                          : 'Đơn đã được xử lý (${status == 'rejected' ? 'Từ chối' : 'Chấp nhận'})',
                      style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}