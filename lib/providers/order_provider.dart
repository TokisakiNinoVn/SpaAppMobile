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
  List listTechnicianRequestEntrust = [];
  List listTechnicianApplyPost = [];
  Map<String, dynamic> workingOrder = {};

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

  Future<bool> checkWorkingOrder() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _orderService.currentWorkingOrder();
      workingOrder = res['data'] ?? [];

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
      final body = {"orderId": idOrder};

      final res = await _orderService.applyPostOrder(body);

      // appLog("Response ứng việc KTV: $res");

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

  Future<bool> entrustOrderAdmin(String id, Map<String, dynamic> body) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _orderService.entrustOrder(id, body);
      if (res['success'] == true) {
        return true;
      }

      errorMessage = res['message'] ?? "Giao việc thất bại";
      appLog("Lỗi giao việc: $res");
      return false;
    } catch (e) {
      errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestEntrustOrder() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await _orderService.requestEntrust();
      if (res['success'] == true) {
        listTechnicianRequestEntrust = res['data'] ?? [];
        return true;
      }

      errorMessage = res['message'] ?? "Lấy danh sách đơn việc được giao thất bại";
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
