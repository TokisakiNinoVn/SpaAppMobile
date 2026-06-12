// lib/screens/widgets/date_of_birth_picker_bottom_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import '../../../config/color_config.dart';

/// Hiển thị bottom sheet chọn ngày sinh
/// Trả về DateTime? nếu người dùng xác nhận, null nếu đóng.
Future<DateTime?> showDateOfBirthPickerBottomSheet({
  required BuildContext context,
  bool? isStatistical,
  String? title,
  bool? isReversal,
  DateTime? initialDate,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) async {
  final now = DateTime.now();

  DateTime tempDate = initialDate ?? maximumDate ?? now;

  final List<Map<String, dynamic>> months = [
    {"month": "Tháng 1", "value": 1},
    {"month": "Tháng 2", "value": 2},
    {"month": "Tháng 3", "value": 3},
    {"month": "Tháng 4", "value": 4},
    {"month": "Tháng 5", "value": 5},
    {"month": "Tháng 6", "value": 6},
    {"month": "Tháng 7", "value": 7},
    {"month": "Tháng 8", "value": 8},
    {"month": "Tháng 9", "value": 9},
    {"month": "Tháng 10", "value": 10},
    {"month": "Tháng 11", "value": 11},
    {"month": "Tháng 12", "value": 12},
  ];

  final fixedExtentController = FixedExtentScrollController(
    initialItem: tempDate.month - 1,
  );

  // Biến trạng thái cho chế độ lọc - khai báo ở đây để không bị reset
  String filterType = 'day'; // 'day' hoặc 'month'

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // Hàm cập nhật tempDate khi thay đổi tháng/năm trong chế độ tháng
        void updateDateForMonthMode(int year, int month) {
          tempDate = DateTime(year, month, 1);
          setState(() {});
        }

        return SafeArea(
          top: false,
          child: Container(
            height: 380,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                _buildHandle(),
                const SizedBox(height: 18),

                Text(
                  title == null ? 'Chọn ngày sinh' : title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),

                const SizedBox(height: 12),

                // Tuỳ chọn chọn kiểu lọc (chỉ hiển thị nếu isStatistical == true)
                if (isStatistical == true) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFilterOption(
                          label: 'Lọc theo ngày',
                          isSelected: filterType == 'day',
                          onTap: () {
                            setState(() {
                              filterType = 'day';
                              // Đảm bảo ngày hợp lệ khi chuyển sang chế độ ngày
                              final lastDay = DateTime(
                                tempDate.year,
                                tempDate.month + 1,
                                0,
                              ).day;
                              if (tempDate.day > lastDay) {
                                tempDate = DateTime(
                                  tempDate.year,
                                  tempDate.month,
                                  lastDay,
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildFilterOption(
                          label: 'Lọc theo tháng',
                          isSelected: filterType == 'month',
                          onTap: () {
                            setState(() {
                              filterType = 'month';
                              // Chuyển về ngày 1 của tháng hiện tại
                              tempDate = DateTime(tempDate.year, tempDate.month, 1);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 6),

                Expanded(
                  child: Row(
                    children: [
                      // Cột ngày - chỉ hiển thị khi filterType == 'day'
                      if (filterType == 'day')
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 42,
                            scrollController: FixedExtentScrollController(
                              initialItem: tempDate.day - 1,
                            ),
                            onSelectedItemChanged: (index) {
                              final newDay = index + 1;
                              tempDate = DateTime(
                                tempDate.year,
                                tempDate.month,
                                newDay,
                              );
                              setState(() {});
                            },
                            children: List.generate(
                              31,
                                  (index) => Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Cột tháng
                      Expanded(
                        flex: filterType == 'month' ? 2 : 2,
                        child: CupertinoPicker(
                          itemExtent: 42,
                          scrollController: fixedExtentController,
                          onSelectedItemChanged: (index) {
                            final monthValue = months[index]['value'] as int;
                            if (filterType == 'month') {
                              updateDateForMonthMode(tempDate.year, monthValue);
                            } else {
                              tempDate = DateTime(
                                tempDate.year,
                                monthValue,
                                tempDate.day,
                              );
                              // Giữ ngày hợp lệ
                              final lastDay = DateTime(
                                tempDate.year,
                                monthValue + 1,
                                0,
                              ).day;
                              if (tempDate.day > lastDay) {
                                tempDate = DateTime(
                                  tempDate.year,
                                  monthValue,
                                  lastDay,
                                );
                              }
                              setState(() {});
                            }
                          },
                          children: months.map((month) {
                            return Center(
                              child: Text(
                                month['month'],
                                style: const TextStyle(fontSize: 18),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Cột năm
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 42,
                          scrollController: FixedExtentScrollController(
                            initialItem: (maximumDate?.year ?? now.year) -
                                tempDate.year,
                          ),
                          onSelectedItemChanged: (index) {
                            final maxYear = maximumDate?.year ?? now.year;
                            final selectedYear = maxYear - index;
                            if (filterType == 'month') {
                              updateDateForMonthMode(selectedYear, tempDate.month);
                            } else {
                              tempDate = DateTime(
                                selectedYear,
                                tempDate.month,
                                tempDate.day,
                              );
                              setState(() {});
                            }
                          },
                          children: List.generate(
                            ((maximumDate?.year ?? now.year) -
                                (minimumDate?.year ?? 1900)) +
                                1,
                                (index) {
                              final maxYear = maximumDate?.year ?? now.year;
                              final year = maxYear - index;
                              return Center(
                                child: Text(
                                  '$year',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _buildConfirmButton(
                  onPressed: () {
                    // Áp dụng giới hạn minimumDate / maximumDate
                    DateTime finalDate = tempDate;
                    if (filterType == 'month') {
                      // Đảm bảo ngày luôn là 1
                      finalDate = DateTime(tempDate.year, tempDate.month, 1);
                    }
                    if (minimumDate != null && finalDate.isBefore(minimumDate!)) {
                      finalDate = minimumDate!;
                      if (filterType == 'month') {
                        finalDate = DateTime(finalDate.year, finalDate.month, 1);
                      }
                    }
                    if (maximumDate != null && finalDate.isAfter(maximumDate!)) {
                      finalDate = maximumDate!;
                      if (filterType == 'month') {
                        finalDate = DateTime(finalDate.year, finalDate.month, 1);
                      }
                    }
                    final Map<String, dynamic> data = {
                      "finalDate": finalDate,
                      "filterType": filterType,
                    };

                    appLog("$data");

                    Navigator.pop(
                      context,
                      filterType == "month"
                          ? data
                          : finalDate, // DateTime
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Xây dựng tuỳ chọn lọc (hai trạng thái: theo ngày / theo tháng)
Widget _buildFilterOption({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? ColorConfig.primary : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
    ),
  );
}

Widget _buildHandle() {
  return Container(
    width: 42,
    height: 5,
    decoration: BoxDecoration(
      color: Colors.grey.shade300,
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

Widget _buildConfirmButton({
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConfig.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
      ),
      child: const Text(
        'Xác nhận',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}