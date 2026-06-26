import 'package:flutter/material.dart';
import 'package:spa_app/config/color_config.dart';
import 'package:spa_app/helper/format_helper.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/screens/components/dashed_divider_component.dart';

class JobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isWorking; // Đang làm việc job này
  final Duration remainingTime;
  final VoidCallback onAccept;
  final VoidCallback? onTap;
  final String Function(Duration) formatRemainingTime;
  final Color Function(Duration) getTimerColor;

  const JobCard({
    super.key,
    required this.job,
    this.onTap,
    required this.isWorking,
    required this.remainingTime,
    required this.onAccept,
    required this.formatRemainingTime,
    required this.getTimerColor,
  });

  bool get isAdminPost => job['isAdminCreate'] ?? false;
  bool get isExpired => remainingTime.isNegative;
  bool get isPrioritize => job['isPrioritize'] ?? false;

  /// Trạng thái chính của job
  String get jobStatus {
    if (isExpired) return "expired";
    if (isWorking) return "working";
    return "available";
  }

  /// Text hiển thị trên nút
  String get actionText {
    if (isExpired) return "Đã hết hạn";

    if (isWorking) {
      return isAdminPost ? "Đang làm việc" : "Đang làm việc";
    }

    return isAdminPost ? "Ứng tuyển" : "Nhận việc";
  }

  /// Màu nút
  Color get buttonColor {
    if (isExpired) return Colors.grey.shade300;

    if (isWorking) {
      return Colors.orange.shade600; // Màu nổi bật khi đang làm
    }

    return isAdminPost ? ColorConfig.primary : ColorConfig.primary;
  }

  /// Icon cho nút
  IconData get buttonIcon {
    if (isWorking) {
      return Icons.access_time_rounded;
    }
    return isAdminPost ? Icons.send_rounded : Icons.handshake_rounded;
  }

  /// Có thể bấm nút không
  bool get canHandleJob {
    if (isExpired) return false;
    if (isWorking) return false; // Đang làm rồi thì không cho bấm lại
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final customer = job['customerId'] ?? {};
    final rawServiceTimePrice =
        job['serviceTimePrice'] ?? job['serviceTimePriceId'];
    final serviceTimePrice =
        (rawServiceTimePrice is Map) ? rawServiceTimePrice : {};

    final gender = customer['gender'] == "male" ? "Khách nam" : "Khách nữ";
    const double borderRadiusAll = 18.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Material(
          color: Colors.white,
          elevation: 1.5,
          borderRadius: BorderRadius.circular(borderRadiusAll),
          child: Container(
            padding: const EdgeInsets.only(
              top: 16,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadiusAll),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Row(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: Colors.orange.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPrioritize ? "Việc ưu tiên" : "Việc mới",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ColorConfig.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isExpired
                                ? Colors.red.shade50
                                : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            isExpired
                                ? "Hết hạn"
                                : (isPrioritize ? "Cần ngay" : "Đang chờ"),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color:
                                  isExpired
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatRemainingTime(remainingTime),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: getTimerColor(remainingTime),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// CUSTOMER INFO
                Text(
                  "$gender${customer['nationality'] != null ? ", ${customer['nationality']}" : ""}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  job['address'] ?? "Địa chỉ đang cập nhật",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 14),
                const DashedDivider(),
                const SizedBox(height: 8),

                /// SERVICE + TIME
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        job['nameService'] ?? "Dịch vụ Spa",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${serviceTimePrice['duration'] ?? 0} phút",
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

                const SizedBox(height: 8),
                const DashedDivider(),
                const SizedBox(height: 12),

                /// PRICE + BUTTON
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// PRICE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bạn sẽ nhận được",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "+ ${FormatHelper.formatPrice(job['pricing']?['technicianReceiveAmount'] ?? job['price'])}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // const SizedBox(width: 4),

                    /// BUTTON
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canHandleJob ? onAccept : null,
                          icon: Icon(buttonIcon, size: 14),
                          label: Text(
                            actionText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: buttonColor,
                            disabledBackgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
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
      ),
    );
  }
}
