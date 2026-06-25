import 'package:flutter/material.dart';

class OrderProgressTimeline extends StatelessWidget {
  final String statusOrderNow;

  const OrderProgressTimeline({
    super.key,
    required this.statusOrderNow,
  });

  static const List<Map<String, dynamic>> steps = [
    {
      "key": "pending",
      "title": "Đã tạo",
      "icon": Icons.receipt_long_rounded,
    },
    {
      "key": "approved",
      "title": "Đã nhận",
      "icon": Icons.assignment_ind_rounded,
    },
    {
      "key": "doing",
      "title": "Đang làm",
      "icon": Icons.handyman_rounded,
    },
    {
      "key": "done",
      "title": "Hoàn thành",
      "icon": Icons.check_circle_rounded,
    },
  ];

  static const Map<String, Map<String, dynamic>> terminalStatuses = {
    "cancelled": {
      "title": "Đơn đã bị hủy",
      "icon": Icons.cancel_rounded,
      "color": Colors.red,
      "description": "Đơn hàng đã bị hủy và không thể tiếp tục xử lý.",
    },
    "expired": {
      "title": "Đơn đã hết hạn",
      "icon": Icons.timer_off_rounded,
      "color": Colors.deepOrange,
      "description": "Đơn hàng đã hết thời gian xử lý.",
    },
  };

  bool get isTerminalStatus {
    return terminalStatuses.containsKey(statusOrderNow);
  }

  int get currentIndex {
    final index = steps.indexWhere(
          (e) => e["key"] == statusOrderNow,
    );

    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    /// ====== ĐƠN BỊ HỦY / HẾT HẠN ======
    if (isTerminalStatus) {
      final status = terminalStatuses[statusOrderNow]!;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: (status["color"] as Color).withOpacity(.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (status["color"] as Color).withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status["icon"],
                color: status["color"],
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status["title"],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: status["color"],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    status["description"],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    /// ====== LUỒNG THÀNH CÔNG ======
    final currentStep = steps[currentIndex];

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
        children: [
          /// Timeline
          Row(
            children: List.generate(
              steps.length * 2 - 1,
                  (index) {
                if (index.isOdd) {
                  final lineIndex = index ~/ 2;

                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: lineIndex < currentIndex
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                }

                final stepIndex = index ~/ 2;

                final isDone = stepIndex < currentIndex;
                final isCurrent = stepIndex == currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? Colors.green
                        : isCurrent
                        ? Colors.orange
                        : Colors.white,
                    border: Border.all(
                      width: 2,
                      color: isDone
                          ? Colors.green
                          : isCurrent
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                    boxShadow: isCurrent
                        ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(.25),
                        blurRadius: 10,
                      ),
                    ]
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                        : Icon(
                      steps[stepIndex]["icon"],
                      size: 16,
                      color: isCurrent
                          ? Colors.white
                          : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          /// Label
          Row(
            children: steps.map((step) {
              final index = steps.indexOf(step);

              final active = index <= currentIndex;
              final current = index == currentIndex;

              return Expanded(
                child: Text(
                  step["title"],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                    current ? FontWeight.w700 : FontWeight.w500,
                    color:
                    active ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
              );
            }).toList(),
          ),

          // const SizedBox(height: 18),
          //
          // /// Trạng thái hiện tại
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.symmetric(
          //     horizontal: 12,
          //     vertical: 10,
          //   ),
          //   decoration: BoxDecoration(
          //     color: Colors.orange.shade50,
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Row(
          //     children: [
          //       Icon(
          //         currentStep["icon"],
          //         size: 18,
          //         color: Colors.orange,
          //       ),
          //
          //       const SizedBox(width: 8),
          //
          //       Expanded(
          //         child: Text(
          //           "Trạng thái hiện tại: ${currentStep["title"]}",
          //           style: const TextStyle(
          //             fontSize: 13,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}