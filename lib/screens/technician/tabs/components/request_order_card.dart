// File: widgets/order_card_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RequestOrderCard extends StatelessWidget {
  final dynamic order;
  final Duration? remainingTime;
  final bool showTimeline;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  const RequestOrderCard({
    super.key,
    required this.order,
    this.remainingTime,
    this.showTimeline = true,
    this.onTap,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final orderId = order['_id'] ?? '';
    final status = order['status'] ?? 'pending';
    final typeOrder = order['typeOrder'] ?? 'order-now';
    final isPrioritize = order['isPrioritize'] ?? false;
    final isExpiringSoon = order['isExpiringSoon'] ?? false;

    final customer = order['customerId'];
    final gender = customer?['gender'] ?? 'male';

    final duration = order['serviceTimePriceId']?['duration'] ?? 0;

    return GestureDetector(
      onTap: onTap ??
              () {
            context.push('/home-technician/orders/$orderId');
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isExpiringSoon &&
              remainingTime != null &&
              remainingTime!.inMinutes <= 1
              ? Border.all(
            color: Colors.orange.shade300,
            width: 1.2,
          )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TOP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isPrioritize
                            ? Icons.bolt_rounded
                            : Icons.home_repair_service_rounded,
                        size: 16,
                        color: isPrioritize
                            ? Colors.orange
                            : Colors.blue.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getTypeOrderText(typeOrder),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // CUSTOMER
            Text(
              _buildCustomerText(customer, status, gender),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            // ADDRESS
            Text(
              order['address'] ?? 'Chưa có địa chỉ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),

            // SERVICE
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      order['nameService'] ?? 'Dịch vụ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$duration phút',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // BOTTOM
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bạn sẽ nhận được',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+${_formatPrice(order['pricing']?['technicianReceiveAmount'] ?? 0)} đ',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5A8F45),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onApply,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF5A8F45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Ứng tuyển',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // TIMELINE
            if (showTimeline) ...[
              const SizedBox(height: 14),
              _CountdownTimeline(
                order: order,
                remainingTime: remainingTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _buildCustomerText(
      dynamic customer,
      String status,
      String gender,
      ) {
    if (status == 'done') {
      final fullname = customer?['fullname'] ?? 'Khách hàng';
      final phone = customer?['phone'] ?? '';

      return '$fullname • $phone';
    }

    return gender == 'female'
        ? 'Khách nữ'
        : 'Khách nam';
  }

  static String _getTypeOrderText(String type) {
    switch (type) {
      case 'order-book':
        return '📅 Việc đặt lịch';

      case 'order-now':
      default:
        return '⚡ Việc mới';
    }
  }

  static String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Cần ngay';

      case 'accepted':
        return 'Đã nhận';

      case 'done':
        return 'Hoàn thành';

      case 'cancel':
        return 'Đã huỷ';

      default:
        return status;
    }
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE59A2F);

      case 'accepted':
        return Colors.blue;

      case 'done':
        return Colors.green;

      case 'cancel':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  static String _formatPrice(num value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
    );
  }
}

class _CountdownTimeline extends StatelessWidget {
  final dynamic order;
  final Duration? remainingTime;

  const _CountdownTimeline({
    required this.order,
    required this.remainingTime,
  });

  @override
  Widget build(BuildContext context) {
    final expiresAt = order['expiresAt'];

    if (expiresAt == null) {
      return const SizedBox.shrink();
    }

    final totalDuration = const Duration(minutes: 5);

    final progress =
    remainingTime != null && remainingTime!.inSeconds > 0
        ? 1 -
        (remainingTime!.inSeconds /
            totalDuration.inSeconds)
        : 1.0;

    final isExpired =
        remainingTime == null ||
            remainingTime!.isNegative ||
            remainingTime!.inSeconds <= 0;

    final progressColor = isExpired
        ? Colors.red
        : progress > 0.8
        ? Colors.orange
        : const Color(0xFF5A8F45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isExpired
                  ? Icons.timer_off_rounded
                  : Icons.timer_outlined,
              size: 16,
              color: progressColor,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isExpired
                    ? 'Đơn đã hết hạn'
                    : 'Còn ${_formatDuration(remainingTime!)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
      ],
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}