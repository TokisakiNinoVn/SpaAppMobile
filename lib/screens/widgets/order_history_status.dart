import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spa_app/config/color_config.dart';

class OrderHistoryStatus extends StatelessWidget {
  final List<dynamic> historyStatus;

  const OrderHistoryStatus({
    super.key,
    required this.historyStatus,
  });

  @override
  Widget build(BuildContext context) {
    final histories = [...historyStatus];

    histories.sort((a, b) {
      final aDate = DateTime.tryParse(a["createdAt"] ?? "") ?? DateTime.now();
      final bDate = DateTime.tryParse(b["createdAt"] ?? "") ?? DateTime.now();

      return bDate.compareTo(aDate);
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Trạng thái đơn việc",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          if (histories.isEmpty)
            const Center(
              child: Text(
                "Chưa có lịch sử",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...List.generate(histories.length, (index) {
              final item = histories[index];
              final isLast = index == histories.length - 1;

              final content =
              (item["content"]?.toString().trim().isNotEmpty ?? false)
                  ? item["content"]
                  : "Không có nội dung";

              final fromStatus =
              (item["fromStatus"]?.toString().trim().isNotEmpty ?? false)
                  ? item["fromStatus"]
                  : null;

              final toStatus =
              (item["toStatus"]?.toString().trim().isNotEmpty ?? false)
                  ? item["toStatus"]
                  : null;

              final createdAt = DateTime.tryParse(
                item["createdAt"] ?? "",
              );

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Timeline bên trái
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: ColorConfig.primary,
                              shape: BoxShape.circle,
                            ),
                          ),

                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    /// Nội dung
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              content,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 4),

                            if (createdAt != null)
                              Text(
                                DateFormat(
                                  'HH:mm dd/MM/yyyy',
                                ).format(createdAt.toLocal()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}