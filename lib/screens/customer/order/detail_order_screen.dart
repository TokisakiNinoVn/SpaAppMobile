import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/helper/format_helper.dart';

class DetailsOrderScreen extends StatefulWidget {
  final String id;
  const DetailsOrderScreen({super.key, required this.id});

  @override
  State<DetailsOrderScreen> createState() => _DetailsOrderScreenState();
}

class _DetailsOrderScreenState extends State<DetailsOrderScreen> {
  final OrderService _orderService = OrderService();

  Map<String, dynamic>? _orderDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  final Color _primaryColor = const Color(0xFF8B7355);
  final Color _backgroundColor = const Color(0xFFF8F5F0);
  final Color _textColor = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _orderService.detailOrder(widget.id);

      if (response['success'] == true) {
        setState(() {
          _orderDetails = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải chi tiết đơn');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ================= UI HELPERS =================

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Đã chấp nhận';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return 'Đang chờ';
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildError();
    }

    final order = _orderDetails!;
    final technician = order['technician'];

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== STATUS =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusColor(order['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _statusColor(order['status']),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusText(order['status']),
                    style: TextStyle(
                      color: _statusColor(order['status']),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== SERVICE =====
            _section(
              'Dịch vụ',
              Column(
                children: [
                  _infoRow('Tên dịch vụ', order['nameService'] ?? ''),
                  _infoRow(
                    'Giá',
                    FormatHelper.formatPrice(order['price']),
                  ),
                  _infoRow('Giờ làm', order['workingHours'] ?? ''),
                ],
              ),
            ),

            // ===== ADDRESS =====
            _section(
              'Địa chỉ',
              _infoRow('Nơi thực hiện', order['address'] ?? ''),
            ),

            // ===== TECHNICIAN =====
            if (technician != null)
              _section(
                'Kỹ thuật viên',
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(
                        technician['avatar']?['url'] ?? '',
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      technician['fullName'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),

            // ===== TIME =====
            _section(
              'Thời gian',
              Column(
                children: [
                  _infoRow(
                    'Tạo lúc',
                    FormatHelper.formatDateTime(order['createdAt']),
                  ),
                  _infoRow(
                    'Gửi lúc',
                    FormatHelper.formatDateTime(order['submittedAt']),
                  ),
                  if (order['rejectedAt'] != null)
                    _infoRow(
                      'Từ chối lúc',
                      FormatHelper.formatDateTime(order['rejectedAt']),
                    ),
                ],
              ),
            ),

            // ===== NOTES =====
            _section(
              'Ghi chú',
              Column(
                children: [
                  _infoRow(
                    'Khách hàng',
                    order['noteCustomer'] ?? '',
                  ),
                  _infoRow(
                    'Kỹ thuật viên',
                    order['noteTechnician'] ?? '',
                  ),
                  if (order['reasonReject'] != null &&
                      order['reasonReject'].toString().isNotEmpty)
                    _infoRow(
                      'Lý do từ chối',
                      order['reasonReject'],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATES =================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: _textColor),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Chi tiết đơn',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Text(
          _errorMessage,
          style: TextStyle(color: _textColor),
        ),
      ),
    );
  }
}
