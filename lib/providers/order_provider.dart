import 'package:flutter/material.dart';
import 'package:spa_app/helper/logger_utils.dart';
import 'package:spa_app/services/customer_service.dart';
import 'package:spa_app/services/order_service.dart';
import 'package:spa_app/services/service_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  bool isLoading = false;
  String? errorMessage;

  List listPost = [];

  Future<bool> loadListPostOrderAdmin() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _orderService.listPostOrder();
      listPost = res['data'] ?? [];

      return true;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}