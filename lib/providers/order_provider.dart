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
  List listTechnicianApplyPost = [];

  Future<bool> loadListPostOrderAdmin(String query) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _orderService.listPostOrder(query);
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

  Future<bool> technicianApplyOrderAdmin(String idOrder) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _orderService.technicianApplyService(idOrder);
      listTechnicianApplyPost = res['data'] ?? [];

      return true;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> technicianApplyOrder(String idOrder) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final body = {
        "orderId": idOrder,
      };

      final res = await _orderService.applyPostOrder(body);

      appLog("Response ứng việc KTV: $res");

      if (res['success'] == true) {
        return true;
      }

      errorMessage = res['message'] ?? "Ứng tuyển thất bại";
      return false;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}