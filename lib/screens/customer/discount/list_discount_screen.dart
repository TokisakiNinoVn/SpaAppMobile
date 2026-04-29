import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/services/user_discount_service.dart';

import '../../../config/color_config.dart';

class ListDiscountScreen extends StatefulWidget {
  const ListDiscountScreen({
    super.key,
  });

  @override
  State<ListDiscountScreen> createState() => _ListDiscountScreenState();
}

class _ListDiscountScreenState extends State<ListDiscountScreen> {
  final UserDiscountService _userDiscountService = UserDiscountService();
  List<dynamic> _discounts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedDiscounts();
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

  Future<void> _deleteDiscount(String id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xóa mã giảm giá'),
        content: Text('Bạn có chắc chắn muốn xóa mã "$code"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFE74C3C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A))),
    );

    try {
      final response = await _userDiscountService.deleteDiscount(id);
      if (response['status'] == 'success') {
        await _loadSavedDiscounts();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Đã xóa mã giảm giá'),
                ],
              ),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Xóa thất bại'),
              backgroundColor: const Color(0xFFE74C3C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
        );
      }
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã "$code"'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF27AE60),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
    );
  }

  void _showDiscountDetail(Map<String, dynamic> discountItem) {
    final discount = discountItem['discount'];
    final status = discountItem['status'];
    final claimedAt = discountItem['claimedAt'];
    final isExpired = status != 'available' || _isDiscountExpired(discount['expiresAt']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      discount['code'] ?? 'Mã giảm giá',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpired ? const Color(0xFF666666) : const Color(0xFF27AE60),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      isExpired ? 'Hết hạn' : 'Có hiệu lực',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (discount['description'] != null && discount['description'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    discount['description'],
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ),

              _buildDetailRow(
                'Giá trị giảm',
                discount['typeDiscount'] == 'fixed'
                    ? '${NumberFormat('#,###').format(discount['value'])}đ'
                    : '${discount['value']}%',
              ),

              if (discount['minOrderValue'] != null && discount['minOrderValue'] > 0)
                _buildDetailRow(
                  'Đơn hàng tối thiểu',
                  '${NumberFormat('#,###').format(discount['minOrderValue'])}đ',
                ),

              if (discount['startAt'] != null)
                _buildDetailRow(
                  'Ngày bắt đầu',
                  _formatDate(discount['startAt']),
                ),

              if (discount['expiresAt'] != null)
                _buildDetailRow(
                  'Ngày hết hạn',
                  _formatDate(discount['expiresAt']),
                ),

              if (discount['maxUses'] != null)
                _buildDetailRow(
                  'Lượt sử dụng',
                  '${discount['usedCount'] ?? 0}/${discount['maxUses']}',
                ),

              if (claimedAt != null)
                _buildDetailRow(
                  'Ngày lưu',
                  _formatDate(claimedAt),
                ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyToClipboard(discount['code']);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy mã'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isExpired ? const Color(0xFF666666) : const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isExpired ? const Color(0xFF666666) : const Color(0xFF1A1A1A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getDiscountDisplayValue(Map<String, dynamic> discount) {
    if (discount['typeDiscount'] == 'fixed') {
      return '${NumberFormat('#,###').format(discount['value'])}đ';
    } else {
      return '${discount['value']}%';
    }
  }

  bool _isDiscountExpired(String expiresAt) {
    try {
      final expiryDate = DateTime.parse(expiresAt);
      return expiryDate.isBefore(DateTime.now());
    } catch (e) {
      return true;
    }
  }

  String _getRemainingTime(String expiresAt) {
    try {
      final expiryDate = DateTime.parse(expiresAt);
      final now = DateTime.now();

      if (expiryDate.isBefore(now)) {
        return 'Đã hết hạn';
      }

      final difference = expiryDate.difference(now);

      if (difference.inDays > 0) {
        return 'Còn ${difference.inDays} ngày';
      } else if (difference.inHours > 0) {
        return 'Còn ${difference.inHours} giờ';
      } else if (difference.inMinutes > 0) {
        return 'Còn ${difference.inMinutes} phút';
      } else {
        return 'Sắp hết hạn';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Mã giảm giá của bạn",
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A1A1A)))
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: const Color(0xFF666666)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF666666)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSavedDiscounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      )
          : _discounts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(Icons.local_offer_outlined, size: 64, color: const Color(0xFF666666)),
            // const SizedBox(height: 16),
            const Text(
              'Chưa có mã giảm giá nào',
              style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy lưu mã giảm giá để sử dụng sau',
              style: TextStyle(fontSize: 14, color: const Color(0xFF666666).withOpacity(0.6)),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadSavedDiscounts,
        color: const Color(0xFF1A1A1A),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _discounts.length,
          itemBuilder: (context, index) {
            final item = _discounts[index];
            final discount = item['discount'];
            final status = item['status'];
            final isExpired = status != 'available' || _isDiscountExpired(discount['expiresAt']);
            final remainingTime = _getRemainingTime(discount['expiresAt']);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF5F5F5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showDiscountDetail(item),
                  borderRadius: BorderRadius.circular(40),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Container(
                        //   width: 50,
                        //   height: 50,
                        //   decoration: BoxDecoration(
                        //     color: const Color(0xFFF5F5F5),
                        //     borderRadius: BorderRadius.circular(40),
                        //   ),
                        //   child: Icon(
                        //     Icons.local_offer_outlined,
                        //     size: 24,
                        //     color: isExpired ? const Color(0xFF666666) : const Color(0xFF1A1A1A),
                        //   ),
                        // ),
                        // const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      discount['code'] ?? 'Mã giảm giá',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isExpired ? const Color(0xFF666666) : const Color(0xFF1A1A1A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isExpired)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(40),
                                      ),
                                      child: const Text(
                                        'Hết hạn',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF666666)),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Giảm: ${_getDiscountDisplayValue(discount)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isExpired ? const Color(0xFF666666) : const Color(0xFF1A1A1A),
                                ),
                              ),
                              if (!isExpired && remainingTime.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: Color(0xFFF39C12),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        remainingTime,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFF39C12),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (discount['minOrderValue'] != null && discount['minOrderValue'] > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Đơn tối thiểu: ${NumberFormat('#,###').format(discount['minOrderValue'])}đ',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isExpired ? const Color(0xFF666666).withOpacity(0.5) : const Color(0xFF666666),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                _copyToClipboard(discount['code']);
                              },
                              icon: Icon(
                                Icons.copy_outlined,
                                size: 20,
                                color: isExpired ? const Color(0xFF666666) : const Color(0xFF1A1A1A),
                              ),
                              tooltip: 'Copy mã',
                            ),
                            IconButton(
                              onPressed: () => _deleteDiscount(item['id'], discount['code']),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: isExpired ? const Color(0xFF666666) : const Color(0xFFE74C3C),
                              ),
                              tooltip: 'Xóa',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}