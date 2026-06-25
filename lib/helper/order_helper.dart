import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';

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

  static String displayTypeOrder(String typeOrder) {
    switch (typeOrder) {
      case 'order-now':
        return 'Đơn đặt ngay';

      case 'book':
        return 'Đơn đặt trước';

      case 'automatic-matching':
        return 'Đơn KTV ngẫu nhiên';

      default:
        return 'Không xác định';
    }
  }

  static String displayStatusOrder(String status) {
    // appLog(status);
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

      case 'reject':
        return 'Từ chối';

      case 'canceled':
        return 'Đã hủy';

      case 'done':
        return 'Hoàn thành';

      default:
        return 'Không xác định';
    }
  }
}
