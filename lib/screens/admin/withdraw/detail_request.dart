import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/admin_router_config.dart';
import 'package:spa_app/services/withdraw_service.dart';
import '../../../helper/format_helper.dart';

class DetailsRequestWithdraw extends StatefulWidget {
  final String id;
  const DetailsRequestWithdraw({
    super.key,
    required this.id,
  });

  @override
  State<DetailsRequestWithdraw> createState() => _DetailsRequestWithdrawState();
}

class _DetailsRequestWithdrawState extends State<DetailsRequestWithdraw> {
  final WithdrawService _withdrawService = WithdrawService();

  Map<String, dynamic>? _withdrawDetail;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDetailsRequestWithdraw();
  }

  Future<void> _loadDetailsRequestWithdraw() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _withdrawService.detailRequestWithdraw(widget.id);

      if (response['status'] == 'success') {
        setState(() {
          _withdrawDetail = response['data'];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ??
            'Không thể tải chi tiết yêu cầu rút tiền');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading withdraw detail: $e');
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'failed':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.black87;
    }
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $fieldName'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Chi tiết yêu cầu rút tiền',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : _buildContent(),
      bottomNavigationBar: _withdrawDetail != null &&
          _withdrawDetail!['status'] == 'pending'
          ? _buildBottomButtons()
          : null,
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadDetailsRequestWithdraw,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_withdrawDetail == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    final bankInfo = _withdrawDetail!['bankInfor'];
    final transaction = _withdrawDetail!['transaction'];
    final status = _withdrawDetail!['status'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status).withOpacity(0.1),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã giao dịch',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _withdrawDetail!['code'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Thông tin ngân hàng
          const Text(
            'Thông tin ngân hàng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRowWithCopy(
                  'Tên ngân hàng',
                  bankInfo?['bankName'] ?? 'N/A',
                  'tên ngân hàng',
                ),
                const SizedBox(height: 12),
                _buildInfoRowWithCopy(
                  'Số tài khoản',
                  bankInfo?['accountNumber'] ?? 'N/A',
                  'số tài khoản',
                ),
                const SizedBox(height: 12),
                _buildInfoRowWithCopy(
                  'Chủ tài khoản',
                  bankInfo?['accountHolder'] ?? 'N/A',
                  'tên chủ tài khoản',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Thông tin giao dịch
          const Text(
            'Thông tin giao dịch',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Số tiền rút', FormatHelper.formatPrice(_withdrawDetail!['amount'] ?? 0)),
                const SizedBox(height: 12),
                _buildInfoRow('Phí', FormatHelper.formatPrice(_withdrawDetail!['fee'] ?? 0)),
                const SizedBox(height: 12),
                _buildInfoRow('Phí', FormatHelper.formatPrice(_withdrawDetail!['fee'] ?? 0)),
                const Divider(height: 20),
                _buildInfoRow(
                  'Thực nhận',
                  FormatHelper.formatPrice(_withdrawDetail!['netAmount'] ?? 0),
                  isBold: true,
                  valueColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Thông tin bổ sung
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Thời gian tạo', FormatHelper.formatDateTime(_withdrawDetail!['createdAt'])),
                if (_withdrawDetail!['processedAt'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Thời gian xử lý', FormatHelper.formatDateTime(_withdrawDetail!['processedAt'])),
                ],
                if (_withdrawDetail!['note'] != null && _withdrawDetail!['note'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Ghi chú', _withdrawDetail!['note']),
                ],
                if (_withdrawDetail!['reasonRefusal'] != null &&
                    _withdrawDetail!['reasonRefusal'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow('Lý do từ chối', _withdrawDetail!['reasonRefusal'], valueColor: Colors.red),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lịch sử giao dịch
          if (transaction != null && transaction['history'] != null) ...[
            const Text(
              'Lịch sử cập nhật',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < transaction['history'].length; i++)
                    _buildHistoryItem(transaction['history'][i]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithCopy(String label, String value, String fieldName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(value, fieldName),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.copy,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> history) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  history['message'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FormatHelper.formatDateTime(history['timestamp']),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  "${AdminRouterConfig.detailWithdraw}/${widget.id}/confirm",
                  extra: {"type": "reject"},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Text(
                'Từ chối',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  "${AdminRouterConfig.detailWithdraw}/${widget.id}/confirm",
                  extra: {"type": "accept"},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConfig.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: const Text(
                'Chấp nhận',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }
}