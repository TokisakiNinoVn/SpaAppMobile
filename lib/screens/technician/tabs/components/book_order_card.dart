// File: widgets/order_card_widget.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/routes/config/technician_router_config.dart';
import 'package:spa_app/screens/components/dashed_divider_component.dart';

class BookOrderCard extends StatelessWidget {
  final dynamic order;
  final Duration? remainingTime;
  final bool showTimeline;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  const BookOrderCard({
    super.key,
    required this.order,
    this.remainingTime,
    this.showTimeline = true,
    this.onTap,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    // appLog("Details order: $order");
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
          final result = context.push('${TechnicianRouterConfig.detailsOrder}/${order['_id']}', extra: false);
          // if (result != null) {
          //   final success = result['success'];
          //   final id = result['id'];
          // }
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
                          isPrioritize ? "Ưu tiên" : "Thường",
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
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 10,
                //     vertical: 5,
                //   ),
                //   decoration: BoxDecoration(
                //     color: _getStatusColor(status),
                //     borderRadius: BorderRadius.circular(999),
                //   ),
                //   child: Text(
                //     _getTypeOrderText(typeOrder),
                //     style: const TextStyle(
                //       fontSize: 12,
                //       color: Colors.white,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ),
              ],
            ),

            const SizedBox(height: 10),

            // CUSTOMER
            Text(
              _buildCustomerText(customer, status, gender),
              style: const TextStyle(
                fontSize: 16,
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
                height: 1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 14),
            const DashedDivider(),
            const SizedBox(height: 5),

            /// SERVICE + DURATION
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['nameService'] ?? "Dịch vụ Spa",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Thời gian làm: ${order["workingHours"]}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// DURATION
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 18,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      "${duration ?? 0} phút",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 5),
            const DashedDivider(),
            const SizedBox(height: 5),

            // BOTTOM
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thu nhập dự kiến',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+ ${FormatHelper.formatPrice(order['pricing']?['technicianReceiveAmount'] ?? 0)} đ',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF5A8F45),
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // const SizedBox(width: 12),
                //
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: ElevatedButton(
                      onPressed: onApply,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: ColorConfig.textError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Hủy đơn',
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
            // if (showTimeline) ...[
            //   const SizedBox(height: 14),
            //   _CountdownTimeline(
            //     order: order,
            //     remainingTime: remainingTime,
            //   ),
            // ],
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

    return gender == 'female' ? 'Khách nữ' : 'Khách nam';
  }
  //
  // static String _getTypeOrderText(String type) {
  //   // appLog("$type");
  //   switch (type) {
  //     case 'book':
  //       return 'Việc đặt lịch';
  //
  //     case 'order-now':
  //       return 'Cần ngay';
  //     default:
  //       return 'Không rõ loại đơn';
  //   }
  // }

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
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isExpired
                    ? 'Đơn đã hết hạn'
                    : '${_formatDuration(remainingTime!)}',
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