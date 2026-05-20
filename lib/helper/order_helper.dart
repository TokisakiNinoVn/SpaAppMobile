import 'package:flutter/material.dart';

class OrderHelper {
  static MaterialColor statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'approved':
        return Colors.green;

      case 'working':
        return Colors.blue;

      case 'expired':
        return Colors.grey;

      case 'rejected':
        return Colors.red;

      case 'canceled':
        return Colors.red;

      case 'done':
        return Colors.teal;

      default:
        return Colors.blueGrey;
    }
  }

  static String displayStatusOrder(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';

      case 'approved':
        return 'Đã chấp nhận';

      case 'working':
        return 'Đang thực hiện';

      case 'expired':
        return 'Đã hết hạn';

      case 'rejected':
        return 'Bị từ chối';

      case 'canceled':
        return 'Đã hủy';

      case 'done':
        return 'Hoàn thành';

      default:
        return 'Không xác định';
    }
  }
}