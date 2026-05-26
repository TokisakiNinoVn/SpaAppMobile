// lib/screens/widgets/date_of_birth_picker_bottom_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/color_config.dart';

/// Hiển thị bottom sheet chọn ngày sinh
/// Trả về DateTime? nếu người dùng xác nhận, null nếu đóng.
Future<DateTime?> showDateOfBirthPickerBottomSheet({
  required BuildContext context,
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

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
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

                const SizedBox(height: 24),

                Expanded(
                  child: Row(
                    children: [
                      /// DAY
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

                      /// MONTH
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          itemExtent: 42,
                          scrollController: fixedExtentController,
                          onSelectedItemChanged: (index) {
                            final monthValue =
                            months[index]['value'] as int;

                            tempDate = DateTime(
                              tempDate.year,
                              monthValue,
                              tempDate.day,
                            );

                            /// Giữ ngày hợp lệ
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

                      /// YEAR
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 42,
                          scrollController: FixedExtentScrollController(
                            initialItem:
                            (maximumDate?.year ?? now.year) -
                                tempDate.year,
                          ),
                          onSelectedItemChanged: (index) {
                            final maxYear =
                                maximumDate?.year ?? now.year;

                            final selectedYear = maxYear - index;

                            tempDate = DateTime(
                              selectedYear,
                              tempDate.month,
                              tempDate.day,
                            );

                            setState(() {});
                          },
                          children: List.generate(
                            ((maximumDate?.year ?? now.year) -
                                (minimumDate?.year ?? 1900)) +
                                1,
                                (index) {
                              final maxYear =
                                  maximumDate?.year ?? now.year;

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
                    if (minimumDate != null &&
                        tempDate.isBefore(minimumDate)) {
                      tempDate = minimumDate;
                    }

                    if (maximumDate != null &&
                        tempDate.isAfter(maximumDate)) {
                      tempDate = maximumDate;
                    }

                    Navigator.pop(context, tempDate);
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