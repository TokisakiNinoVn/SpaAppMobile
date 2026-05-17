// lib/screens/widgets/date_of_birth_picker_bottom_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/color_config.dart';

/// Hiển thị bottom sheet chọn ngày sinh với CupertinoDatePicker
/// Trả về DateTime? nếu người dùng xác nhận, null nếu đóng mà không chọn.
Future<DateTime?> showDateOfBirthPickerBottomSheet({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? minimumDate,
  DateTime? maximumDate,
}) async {
  DateTime tempDate = initialDate ?? (maximumDate ?? DateTime.now());

  return showModalBottomSheet<DateTime>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: 380,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHandle(),
              const SizedBox(height: 16),
              const Text(
                'Chọn ngày sinh',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: minimumDate,
                  maximumDate: maximumDate,
                  onDateTimeChanged: (DateTime newDate) {
                    tempDate = newDate;
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildConfirmButton(
                onPressed: () => Navigator.pop(context, tempDate),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildHandle() {
  return Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: Colors.grey[300],
      borderRadius: BorderRadius.circular(10),
    ),
  );
}

Widget _buildConfirmButton({required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConfig.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 0,
      ),
      child: const Text('Xác nhận'),
    ),
  );
}