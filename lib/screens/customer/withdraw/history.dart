import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/services/withdraw_service.dart';

import 'package:spa_app/services/like_service.dart';
import 'package:spa_app/services/technician_service.dart';
import 'package:spa_app/services/notification_service.dart';
import '../../../helper/format_helper.dart';
import '../../../routes/config/customer_router_config.dart';

class HistoryWithdrawScreen extends StatefulWidget {
  @override
  State<HistoryWithdrawScreen> createState() => _HistoryWithdrawScreenState();
}

class _HistoryWithdrawScreenState extends State<HistoryWithdrawScreen> {
  final WithdrawService _withdrawService = WithdrawService();

  List<dynamic> _historyDepositList = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistoryDeposit();
  }

  Future<void> _loadHistoryDeposit() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await _withdrawService.historyWithdraw();

      if (response['status'] == 'success') {
        setState(() {
          _historyDepositList = response['data']['withdraws'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Không thể tải lịch sử nạp tiền');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      print('Error loading withdraw history: $e');
    }
  }

  void _showTransactionDetailBottomSheet(Map<String, dynamic> withdraw) {
    final transaction = withdraw['transaction'] as Map<String, dynamic>;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chi tiết giao dịch',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Nội dung chi tiết
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Mã giao dịch', withdraw['code'] ?? transaction['code']),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số tiền', FormatHelper.formatPrice(transaction['amount'])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Trạng thái', _getStatusText(transaction['status']),
                      textColor: _getStatusColor(transaction['status'])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Loại giao dịch', _getTransactionTypeText(transaction['type'])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Số dư mới', FormatHelper.formatPrice(transaction['newBalance'])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Thời gian', FormatHelper.formatDateTime(transaction['createdAt'])),
                  const SizedBox(height: 12),
                  if (transaction['details'] != null)
                    _buildDetailRow('Mô tả', transaction['details']),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'success':
        return 'Thành công';
      case 'pending':
        return 'Đang xử lý';
      case 'failed':
        return 'Thất bại';
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

  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'withdraw':
        return 'Nạp tiền';
      case 'withdraw':
        return 'Rút tiền';
      case 'payment':
        return 'Thanh toán';
      default:
        return type;
    }
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
            Text(
              "Lịch sử rút tiền",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
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
              onPressed: _loadHistoryDeposit,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_historyDepositList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch sử nạp tiền',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _historyDepositList.length,
      itemBuilder: (context, index) {
        final withdraw = _historyDepositList[index];
        final transaction = withdraw['transaction'] as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showTransactionDetailBottomSheet(withdraw),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          withdraw['code'] ?? transaction['code'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusText(transaction['status']),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(transaction['status']),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số tiền:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        FormatHelper.formatPrice(transaction['amount']),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thời gian:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        FormatHelper.formatDateTime(withdraw['createdAt']),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}