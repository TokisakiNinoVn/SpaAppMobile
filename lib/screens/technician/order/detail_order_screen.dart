import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/helper/order_helper.dart';
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
      appLog("Chi tiet don: ${response['data']}");
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

  // Helper to get pricing data safely
  Map<String, dynamic>? get _pricing => _orderDetails?['pricing'];
  Map<String, dynamic>? get _serviceTimePrice => _orderDetails?['serviceTimePrice'];
  Map<String, dynamic>? get _technician => _orderDetails?['technician'];

  // Section builder with nice styling
  Widget _buildSection(String title, Widget child, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: ColorConfig.primary),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: ColorConfig.textBlack,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: ColorConfig.textBlack.withOpacity(0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? ColorConfig.primary : ColorConfig.textBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = OrderHelper.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            OrderHelper.displayStatusOrder(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? ColorConfig.primary : ColorConfig.textBlack.withOpacity(0.8),
            ),
          ),
          Text(
            FormatHelper.formatPrice(amount),
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? ColorConfig.primary : ColorConfig.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: ColorConfig.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadOrderDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _orderDetails!;
    final status = order['status'] ?? '';
    final isPrioritize = order['isPrioritize'] ?? false;
    final deposit = order['deposit'] ?? 0;

    return Scaffold(
      backgroundColor: ColorConfig.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chi tiết đơn việc',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: ColorConfig.textBlack,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            // Header with status and priority
            Row(
              children: [
                _buildStatusChip(status),
                const Spacer(),
                if (isPrioritize)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.flash_on, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Ưu tiên',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Pricing Card
            if (_pricing != null)
              _buildSection(
                'Bảng giá',
                Column(
                  children: [
                    _buildPriceRow('Giá dịch vụ', _pricing!['serviceAmount'] ?? 0),
                    if ((_pricing!['discountAmount'] ?? 0) > 0)
                      _buildPriceRow('Giảm giá', -(_pricing!['discountAmount'] ?? 0)),
                    if ((_pricing!['extraAmount'] ?? 0) > 0)
                      _buildPriceRow('Chi phí hỗ trợ: ', _pricing!['extraAmount'] ?? 0),
                    const Divider(height: 20, thickness: 1),
                    _buildPriceRow('Tổng thanh toán', _pricing!['finalAmount'] ?? 0, isTotal: true),
                    // if (deposit > 0) ...[
                    //   const SizedBox(height: 8),
                    //   Container(
                    //     padding: const EdgeInsets.all(8),
                    //     decoration: BoxDecoration(
                    //       color: ColorConfig.primary.withOpacity(0.08),
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //     child: Row(
                    //       children: [
                    //         Icon(Icons.account_balance_wallet, size: 18, color: ColorConfig.primary),
                    //         const SizedBox(width: 8),
                    //         Text(
                    //           'Đã đặt cọc: ${FormatHelper.formatPrice(deposit)}',
                    //           style: const TextStyle(fontWeight: FontWeight.w500),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ],
                  ],
                ),
                icon: Icons.receipt_long,
              ),

            // Service info
            _buildSection(
              'Thông tin dịch vụ',
              Column(
                children: [
                  _infoRow('Tên dịch vụ', order['nameService'] ?? ''),
                  if (_serviceTimePrice != null) ...[
                    _infoRow('Thời lượng', '${_serviceTimePrice!['duration']} phút'),
                  ],
                  _infoRow('Hình thức', _getTypeOrderText(order['typeOrder'])),
                  if (order['paymentMethod'] != null && order['paymentMethod'].toString().isNotEmpty)
                    _infoRow('Thanh toán', _getPaymentMethodText(order['paymentMethod'])),
                ],
              ),
              icon: Icons.spa,
            ),

            // Technician
            if (_technician != null)
              _buildSection(
                'Kỹ thuật viên',
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                          FormatHelper.formatNetworkImageUrl(_technician!['avatar']?['url'] ?? ''),
                        ),
                        backgroundColor: Colors.grey.shade200,
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _technician!['fullName'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ColorConfig.textBlack,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _technician!['gender'] == 'female' ? 'Nữ' : 'Nam',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                icon: Icons.person_outline,
              ),

            // Address
            _buildSection(
              'Địa chỉ',
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon(Icons.location_on_outlined, size: 20, color: ColorConfig.primary.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order['address'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
              icon: Icons.home_outlined,
            ),

            // Time info
            // _buildSection(
            //   'Thời gian',
            //   Column(
            //     children: [
            //       _infoRow('Ngày tạo', FormatHelper.formatDateTime(order['createdAt'])),
            //       _infoRow('Ngày gửi', FormatHelper.formatDateTime(order['submittedAt'])),
            //       if (order['expiresAt'] != null && order['typeOrder'] == 'order-now')
            //         _infoRow(
            //           'Hết hạn lúc',
            //           FormatHelper.formatDateTime(order['expiresAt']),
            //           isHighlight: DateTime.now().isAfter(DateTime.parse(order['expiresAt'])),
            //         ),
            //       if (order['approvedAt'] != null)
            //         _infoRow('Duyệt lúc', FormatHelper.formatDateTime(order['approvedAt'])),
            //       if (order['rejectedAt'] != null)
            //         _infoRow('Từ chối lúc', FormatHelper.formatDateTime(order['rejectedAt'])),
            //     ],
            //   ),
            //   icon: Icons.access_time,
            // ),

            // Notes
            if ((order['noteCustomer'] != null && order['noteCustomer'].toString().isNotEmpty) ||
                (order['noteTechnician'] != null && order['noteTechnician'].toString().isNotEmpty) ||
                (order['reasonReject'] != null && order['reasonReject'].toString().isNotEmpty))
              _buildSection(
                'Ghi chú',
                Column(
                  children: [
                    if (order['noteCustomer'] != null && order['noteCustomer'].toString().isNotEmpty)
                      _infoRow('Khách hàng', order['noteCustomer']),
                    if (order['noteTechnician'] != null && order['noteTechnician'].toString().isNotEmpty)
                      _infoRow('KTV', order['noteTechnician']),
                    if (order['reasonReject'] != null && order['reasonReject'].toString().isNotEmpty)
                      _infoRow('Lý do từ chối', order['reasonReject']),
                  ],
                ),
                icon: Icons.note_alt_outlined,
              ),
          ],
        ),
      ),
    );
  }

  String _getTypeOrderText(String? type) {
    switch (type) {
      case 'order-now':
        return 'Đặt ngay';
      case 'schedule':
        return 'Đặt lịch';
      default:
        return type ?? '—';
    }
  }

  String _getPaymentMethodText(String? method) {
    switch (method) {
      case 'cash':
        return 'Tiền mặt';
      case 'momo':
        return 'Ví MoMo';
      case 'bank':
        return 'Chuyển khoản';
      default:
        return method ?? '—';
    }
  }
}